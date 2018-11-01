unit module LogP6::Pattern;

#use Grammar::Tracer;

role PatternPart {
	method show($) { ... }
}

class Trait does PatternPart {
	method show($context) {
		$context.trait;
	}
}

class Tid does PatternPart {
	method show($context) {
		$context.tid;
	}
}

class Tname does PatternPart {
	method show($context) {
		$context.tname // '';
	}
}

class Ndc does PatternPart {
	method show($context) {
		$context.ndc;
	}
}

class Msg does PatternPart {
	method show($context) {
		$context.msg;
	}
}

class Mdc does PatternPart {
	has $.key is required;
	method show($context) {
		$context.mdc{$!key} // '';
	}
}

class Glue does PatternPart {
	has $.glue is required;
	method new($str) {
		self.bless(glue => $str);
	}
	method show($context) {
		$.glue;
	}
}

class X does PatternPart {
	has $.pieces;
	method show($context) {
		with $context.x() {
			return ($!pieces>>.show($_)).join;
		}
		return '';
	}
}

class XMsg does PatternPart {
	method show($x) {
		$x.message;
	}
}

class XName does PatternPart {
	method show($x) {
		$x.^name;
	}
}

class XTrace does PatternPart {
	method show($x) {
		$x.backtrace;
	}
}

my $digits = ('00', '01' ... '99').list;
my $months = ('', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec').list;

class Date does PatternPart {
	has $.pieces;
	method show($context) {
		with $context.date() {
			return ($!pieces>>.show($_)).join;
		}
		return '';
	}
}

class DateYearFour does PatternPart {
	method show($d) {
		$d.year;
	}
}

class DateYearTwo does PatternPart {
	method show($d) {
		$digits[$d.year % 100];
	}
}

class DateMonthWord does PatternPart {
	method show($d) {
		$months[$d.month];
	}
}

class DateMonthNum does PatternPart {
	method show($d) {
		$digits[$d.month];
	}
}

class DateDay does PatternPart {
	method show($d) {
		$digits[$d.day];
	}
}

class DateHour does PatternPart {
	method show($d) {
		$digits[$d.hour];
	}
}

class DateMinute does PatternPart {
	method show($d) {
		$digits[$d.minute];
	}
}

class DateSecond does PatternPart {
	method show($d) {
		$digits[$d.whole-second];
	}
}

class DateMSecond does PatternPart {
	method show($d) {
		round(($d.second - $d.whole-second) * 1000);
	}
}

class DateZone does PatternPart {
	method show($d) {
		$d.timezone;
	}
}


#++ %trait - logger name (trait)
#++ %tid - thread id
#++ %tname - thread name
#++ %msg - message
#++ %ndc - ndc-stack
#++ %mdc{key} - mdc-value
#++ %x{$msg $name $trace} - exception {message class-name backtrace}
# %date{$yyyy-$yy-$mm-$mmm-$dd $hh:$mm:$ss $z} - date and time
# %level{WARN=W, DEBUG=D, ERROR=E, TRACE=T, INFO=I, length=2}
grammar Grammar is export {
	token TOP { <item>* }

	proto token item { * }
	token item:sym<trait> { '%trait' }
	token item:sym<tid> { '%tid' }
	token item:sym<tname> { '%tname' }
	token item:sym<msg> { '%msg' }
	token item:sym<ndc> { '%ndc' }
	token item:sym<glue> { $<text>=<-[%]>+ }

	token word { $<text>=<-[\s}]>+ }

	token item:sym<x> { '%x'<x-params>? }
	token x-params { \{ <x-param>+ \} }
	proto token x-param { * }
	token x-param:sym<msg> { '$msg' }
	token x-param:sym<name> { '$name' }
	token x-param:sym<trace> { '$trace' }
	token x-param:sym<glue> { $<text>=<-[$}]>+ }

	token item:sym<date> { '%date'<date-params>? }
	token date-params { \{ <date-param>+ \} }
	proto token date-param { * }
	token date-param:sym<year> { '$' $<l>=y ** 2..4 }
	token date-param:sym<month> { '$' $<l>=M ** 2..3 }
	token date-param:sym<day> { '$dd' }
	token date-param:sym<hour> { '$hh' }
	token date-param:sym<minute> { '$mm' }
	token date-param:sym<second> { '$ss' }
	token date-param:sym<msecond> { '$mss' }
	token date-param:sym<zone> { '$z' }
	token date-param:sym<glue> { $<text>=<-[$}]>+ }

	token item:sym<mdc> { '%mdc'<mdc-param> }
	token mdc-param { \{ <word> \} }

	token item:sym<level> { '%level'<level-params>? }
	token level-params { \{ <level-param>+ \} }
	proto rule level-param { * }
	rule level-param:sym<trace> { 'TRACE' '=' <word> }
	rule level-param:sym<debug> { 'DEBUG' '=' <word> }
	rule level-param:sym<info> { 'INFO' '=' <word> }
	rule level-param:sym<warn> { 'WARN' '=' <word> }
	rule level-param:sym<error> { 'ERROR' '=' <word> }
	rule level-param:sym<length> { 'length' '=' <word> }
}

class Actions is export {
	method TOP($/) {
		make $<item>>>.made.List;
	}

	method item:sym<trait>($/) {
		make Trait;
	}

	method item:sym<tid>($/) {
		make Tid;
	}

	method item:sym<tname>($/) {
		make Tname;
	}

	method item:sym<msg>($/) {
		make Msg;
	}

	method item:sym<ndc>($/) {
		make Ndc;
	}

	method item:sym<mdc>($/) {
		make Mdc.new(key => $<mdc-param>.made);
	}

	method mdc-param($/) {
		make $<word>.made;
	}

	method item:sym<glue>($/) {
		make Glue.new($<text>.Str);
	}

	method word($/) {
		make $<text>.Str;
	}

	method item:sym<x>($/) {
		with $<x-params> {
			make X.new(pieces => $<x-params>.made);
		} else {
			make X.new(pieces => (XName, Glue.new(': '), XMsg));
		}
	}

	method x-params($/) {
		make $<x-param>>>.made.List;
	}

	method x-param:sym<msg>($/) {
		make XMsg;
	}

	method x-param:sym<name>($/) {
		make XName;
	}

	method x-param:sym<trace>($/) {
		make XTrace.new;
	}

	method x-param:sym<glue>($/) {
		make Glue.new($<text>.Str);
	}

	method item:sym<date>($/) {
		with $<date-params> {
			make Date.new(pieces => $<date-params>.made);
		} else {
			make Date.new(pieces => (DateHour, Glue.new(':'), DateMinute, Glue.new(':'),
							DateSecond, Glue.new(':'), DateMSecond));
		}
	}

	method date-params($/) {
		make $<date-param>>>.made.List;
	}

	method date-param:sym<year>($/) {
		make $<l>.chars == 4 ?? DateYearFour !! DateYearTwo;
	}

	method date-param:sym<month>($/) {
		make $<l>.chars == 2 ?? DateMonthNum !! DateMonthWord;
	}

	method date-param:sym<day>($/) {
		make DateDay;
	}

	method date-param:sym<hour>($/) {
		make DateHour;
	}

	method date-param:sym<minute>($/) {
		make DateMinute;
	}

	method date-param:sym<second>($/) {
		make DateSecond;
	}

	method date-param:sym<msecond>($/) {
		make DateMSecond;
	}

	method date-param:sym<zone>($/) {
		make DateZone;
	}

	method date-param:sym<glue>($/) {
		make Glue.new($<text>.Str);
	}
}


#say LogP6::Pattern::Grammar.parse(
#		'%date{$yyyy-$yy-$MM-$MMM-$dd $hh:$mm:$ss:$mss $z}[%tid|%tname](%trait){user=%mdc{user},%ndc} %msg' ~ " \%x\{cause \$name: \$msg\n\$trace}",
#		actions => LogP6::Pattern::Actions
#).made;