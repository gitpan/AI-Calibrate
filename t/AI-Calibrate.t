#  -*- Mode: CPerl -*-
use strict;
# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl AI-Calibrate.t'

#########################

use Test::More tests => 34;
BEGIN { use_ok('AI::Calibrate', ':all') };

srand;

#  Given an array reference, shuffle the array.  This is the Fisher-Yates code
#  from The Perl Cookbook.
sub shuffle_array {
   my($array) = shift;
   my($i);
   for ($i = @$array ; --$i; ) {
      my $j = int rand ($i+1);
      next if $i == $j;
      @$array[$i,$j] = @$array[$j,$i]
   }
}

#  These points are from the ROCCH-PAV paper, Table 1
#  Format of each point is [Threshold, Class].
my $points = [
              [.9, 1],
              [.8, 1],
              [.7, 0],
              [.6, 1],
              [.55, 1],
              [.5, 1],
              [.45, 0],
              [.4, 1],
              [.35, 1],
              [.3, 0 ],
              [.27, 1],
              [.2, 0 ],
              [.18, 0],
              [.1, 1 ],
              [.02, 0]
             ];

my $calibrated_expected =
  [
   [.9,    1 ],
   [.7,  3/4 ],
   [.45, 2/3 ],
   [.3,  1/2 ],
   [.2,  1/3 ],
   [.02,   0 ]
  ];

my $calibrated_got = calibrate( $points, 1 );

pass("ran_ok");

is_deeply($calibrated_got, $calibrated_expected, "pre-sorted calibration");

#  Shuffle the arrays a bit and try calibrating again

for (1 .. 10) {
    shuffle_array($points);
    my $calibrated_got = calibrate($points, 0);
    is_deeply($calibrated_got, $calibrated_expected, "unsorted cal $_");
}

#  Tweak the thresholds

for (1 .. 10) {
    my $delta = rand;
    my @delta_points;
    for my $point (@$points) {
        my($thresh, $class) = @$point;
        push(@delta_points, [ $thresh+$delta, $class]);
    }
    my @delta_expected;
    for my $point (@$calibrated_expected) {
        my($thresh, $class) = @$point;
        push(@delta_expected, [ $thresh+$delta, $class]);
    }
    my $delta_got = calibrate(\@delta_points, 0);
    is_deeply($delta_got, \@delta_expected, "unsorted cal $_");
}

my @test_estimates =
  ( [100, 1],
    [.9,    1 ],
    [.8,   3/4],
    [.7,  3/4 ],
    [.5,  2/3 ],
    [.45, 2/3 ],
    [.35, 1/2 ],
    [.3,  1/2 ],
    [.2,  1/3 ],
    [.02,   0 ],
    [.00001, 0]
);

for my $pair (@test_estimates) {
    my($score, $prob_expected) = @$pair;
    my $prob_got = score_prob($calibrated_got, $score);
    is($prob_got, $prob_expected, "score_prob test @$pair");
}
