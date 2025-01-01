use Test::More tests => 18;
use strict; use warnings;

use FindBin;
use lib "$FindBin::Bin/../lib", "$FindBin::Bin/../blib/arch", "$FindBin::Bin/../blib/lib";

use_ok('utils::curl', qw());

my @warns;
my $warn = 0;
$SIG{__WARN__} = sub {$warn++; push @warns, $_[0]};

my $DO_DIE = 1;
sub fn_write {
    my ($curl_e, $buffer, $output) = @_;
    die "SOME DIE TEST 01" if $DO_DIE;
    $$output .= $buffer;
    return length($buffer);
}

my $LOGGED_ERRROR = "";
sub fn_write_bis {
    my ($curl_e, $buffer, $output) = @_;
    # local test
    local $@;
    eval {
        die "SOME DIE TEST 01\n" if $DO_DIE;
    };
    if($@){
        chomp(my $err = $@);
        $LOGGED_ERRROR = $err;
    }
    $$output .= $buffer;
    return length($buffer);
}

my $LOGGED_ERRROR_TRIS = "";
sub fn_write_tris {
    my ($curl_e, $buffer, $output) = @_;
    # no local test, $@ can't leak
    eval {
        die "SOME DIE TEST 01\n" if $DO_DIE;
    };
    if($@){
        chomp(my $err = $@);
        $LOGGED_ERRROR = $err;
    }
    $$output .= $buffer;
    return length($buffer);
}

my $k;
my $e = http::curl_easy_init();
$k |= http::curl_easy_setopt($e, http::CURLOPT_URL(), 'http://www.example.com/');
$k |= http::curl_easy_setopt($e, http::CURLOPT_WRITEFUNCTION(), \&fn_write);
$k |= http::curl_easy_setopt($e, http::CURLOPT_WRITEDATA(), \(my $out = ''));
$k |= http::curl_easy_setopt($e, http::CURLOPT_VERBOSE(), 0);
is($k, http::CURLE_OK(), 'curl_easy_setopt');
my $d = http::curl_easy_duphandle($e);
my $p = http::curl_easy_duphandle($e);

$k |= http::curl_easy_perform($e);
is($k, http::CURLE_WRITE_ERROR(), 'curl_easy_perform');
is($out, '', 'no body: '.$out);
like(join(',', @warns), qr/SOME DIE TEST 01/, 'callback function called: ok WARN');

$out = '';
$DO_DIE = 0;
$k = 0;
@warns = ();
$k |= http::curl_easy_perform($e);
is($k, http::CURLE_OK(), 'curl_easy_perform');
isnt($out, '', 'got body');
is(scalar @warns, 0, 'no warnings');


$out = '';
$DO_DIE = 1;
$k = 0;
@warns = ();
$k |= http::curl_easy_setopt($d, http::CURLOPT_WRITEFUNCTION(), \&fn_write_bis);
is($k, http::CURLE_OK(), 'curl_easy_setopt');
$k = 0;
$k |= http::curl_easy_perform($d);
is($k, http::CURLE_OK(), 'curl_easy_perform');
isnt($out, '', 'got also body');
is(scalar @warns, 0, 'no warnings');
like($LOGGED_ERRROR, qr/SOME DIE TEST 01/, 'callback function called: ok ERR: '.$LOGGED_ERRROR);

$out = '';
$DO_DIE = 1;
$k = 0;
@warns = ();
$k |= http::curl_easy_setopt($p, http::CURLOPT_WRITEFUNCTION(), \&fn_write_tris);
is($k, http::CURLE_OK(), 'curl_easy_setopt');
$k = 0;
$k |= http::curl_easy_perform($p);
is($k, http::CURLE_OK(), 'curl_easy_perform');
isnt($out, '', 'got also body');
is(scalar @warns, 0, 'no warnings');
like($LOGGED_ERRROR, qr/SOME DIE TEST 01/, 'callback function called: ok ERR: '.$LOGGED_ERRROR);

http::curl_easy_cleanup($e);
http::curl_easy_cleanup($d);
http::curl_easy_cleanup($p);

