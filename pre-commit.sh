#!/usr/bin/perl -w
#
#
# To enable this hook, copy to "pre-commit" in the repo's git dir and make it executable.
#
# You will need to change $PARSER to the path that you've installed the Kynetx parser. 
#



my $against;
if (`git rev-parse --verify HEAD`) {
$against="HEAD";
} else {
# Initial commit: diff against an empty tree object
$against="4b825dc642cb6eb9a060e54bf8d69288fbee4904";
}

# install using
# npm install -g krl-compiler
my $PARSER="krl-compiler --verify";
my $PICO_ENGINE= $ENV{'PICO_ENGINE'} || "localhost:8080";

my $allownoparse=`git config hooks.allownoparse`;
#print $allownoparse;

my $parse_error = 0;

# Cross platform projects tend to avoid non-ascii filenames; prevent
# them from being added to the repository. We exploit the fact that the
# printable range starts at the space character and ends with tilde.
if (! defined $allownoparse || length($allownoparse) == 0) {

    my $file_list = `git diff --name-only --diff-filter=ACM $against`;
    my ($parse_result, $file, @rids);
    foreach $f (split(/\n/, $file_list)) {
      next unless $f =~ m/\.krl$/;
      $file = $f;
      $parse_result = `cat $f | $PARSER 2>&1`;
      	print "$f: Parser says $parse_result";
      if ($?) {
        $parse_error = 1;
        last
      } else {
          my @rid_line = grep(/"rid"/, split(/\n/,$parse_result));
          my @rid_text = split(/:/, $rid_line[0]);
          my $rid = $rid_text[1];
          $rid =~ s/^.*"(.+)".*$/$1/;
          push @rids, $rid;
      }
    }

    if ($parse_error) {
        die "Parse errors in $file:\n$parse_result\nYou can disable checking by setting the hook.allownoparse to true\n";
    } else {
        foreach $rid (@rids) {
            my $flush_url = "http://$PICO_ENGINE/api/ruleset/flush/$rid";
            # print $flush_url, "\n";
            `curl $flush_url 2>&1`;
            print "Flushing ", $rid, "\n";
        }
    }
}
