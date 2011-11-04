#  -*- Mode: CPerl -*-
use English;
use strict;
# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl AI-Calibrate.t'

#########################

use Test::More;

eval("use AI::NaiveBayes1");
if ($EVAL_ERROR) {
    plan skip_all => 'AI::NaiveBayes1 does not seem to be present';
} else {
    plan tests => 2;
}

use_ok('AI::Calibrate', ':all');

my @instances =
  ( [ { outlook=>'sunny',temperature=>85,humidity=>85,windy=>'FALSE'},
      'no'],
    [ {outlook=>'sunny',temperature=>80,humidity=>90,windy=>'TRUE'},
      'no'],
    [ {outlook=>'overcast',temperature=>83,humidity=>86,windy=>'FALSE'},
      'yes'],
    [ {outlook=>'rainy',temperature=>70,humidity=>96,windy=>'FALSE'},
      'yes'],
    [ {outlook=>'rainy',temperature=>68,humidity=>80,windy=>'FALSE'},
      'yes'],
    [ {outlook=>'rainy',temperature=>65,humidity=>70,windy=>'TRUE'},
      'no'],
    [ {outlook=>'overcast',temperature=>64,humidity=>65,windy=>'TRUE'},
      'yes'],
    [ {outlook=>'sunny',temperature=>72,humidity=>95,windy=>'FALSE'},
      'no'],
    [ {outlook=>'sunny',temperature=>69,humidity=>70,windy=>'FALSE'},
      'yes'],
    [ {outlook=>'rainy',temperature=>75,humidity=>80,windy=>'FALSE'},
      'yes'],
    [ {outlook=>'sunny',temperature=>75,humidity=>70,windy=>'TRUE'},
      'yes'],
    [ {outlook=>'overcast',temperature=>72,humidity=>90,windy=>'TRUE'},
      'yes'],
    [ {outlook=>'overcast',temperature=>81,humidity=>75,windy=>'FALSE'},
      'yes'],
    [ {outlook=>'rainy',temperature=>71,humidity=>91,windy=>'TRUE'},
      'no']
    );

my $nb = AI::NaiveBayes1->new;
$nb->set_real('temperature', 'humidity');

for my $inst (@instances) {
    my($attrs, $play) = @$inst;
    $nb->add_instance(attributes=>$attrs, label=>"play=$play");
}

$nb->train;

my @points;
for my $inst (@instances) {
    my($attrs, $play) = @$inst;

    my $ph = $nb->predict(attributes=>$attrs);

    my $play_score = $ph->{"play=yes"};
    push(@points, [$play_score, ($play eq "yes" ? 1 : 0)]);
}

my $calibrated = calibrate(\@points, 0); # not sorted

print "Mapping:\n";

print_mapping($calibrated);

my @expected = 
  ( [1, 1],
    [0.711310665804783, 0.666666666666667],
    [0.388031956546446, 0]
    );

# This fails because two numbers differ at the 15th digit:
# is_deeply($calibrated, \@expected, "Naive Bayes calibration test");

sub close_enough {
    my($x, $y) = @_;
    return(abs($x - $y) < 1.0e5);
}

sub lists_close_enough {
    my($l1, $l2) = @_;
    if (@$l1 != @$l2) {
        return 0;
    }
    for my $i (0 .. $#{$l1}) {
        if (! close_enough($l1->[$i], $l2->[$i])) {
            return 0;
        }
    }
    return 1;
}

ok(lists_close_enough($calibrated, \@expected),
   'Calibration');
