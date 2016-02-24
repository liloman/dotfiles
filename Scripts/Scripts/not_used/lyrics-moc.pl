#!/usr/bin/perl -w
#===============================================================================#{{{
#
#         FILE:  moc-lyrics.pl
#
#        USAGE:  ./moc-lyrics.pl 
#                   -a  --artist ARTIST
#                   -t  --title  TITLE
#
#  DESCRIPTION:  Retrieves lyrics from some sites
#                To customize its behaviour have a look at the variables under
#                "Definitions"
#
#        NOTES:  Lyrics::Fetcher is free software by David Precious
#                (URL: http://search.cpan.org/~bigpresh/)
#       AUTHOR:  kb, <unixprog@gmail.com>
#      COMPANY:  "freelance" :-)
#      VERSION:  ---
#      CREATED:  2007-12-02 11:08:50Z
#     REVISION:  $Id: moc-lyrics.pl 6 2008-05-25 15:15:01Z kb $
#===============================================================================#}}}

use strict;
use warnings;
use Data::Dumper;
use Lyrics::Fetcher;
use Lyrics::Fetcher::Cache;
use Encode;
use Getopt::Lazy
    'artist|a=s'  => 'Artist',
    'title|t=s'   => 'Song Title',
    -summary    => 'Looks up lyrics in LyricWiki (or other sources, see source)',
    -usage      => '%c %o',
;
&GetOptions;
print &Getopt::Lazy::show_help && exit unless ($artist && $title);

##################################################
# Definitions
###################################################{{{
our $INDENT  = 4;      # Number of spaces for indentation (if any)
our $HEADING = 1;      # Print a heading?
our $SOURCE  = 1;      # Show source of lyrics?
our $PAGER   = '/usr/bin/view -'; # Pager to show lyrics (less,more,most,less.sh,info,cat etc.)
our $TRYHARD = 1;      # Try harder by changing case if nothing is found? (this means
                       # a lot  of bandwith usage, use with care on slow connections)
our $DEBUG   = 1;      # Show debug warnings?

# Comment in/out what you want. order does matter.
# For more check out Lyrics::Fetcher's CPAN page
our @sources = (
     'LeosLyrics', # iba muy lenta ultimamente
     'LyricWiki',
#     'LyricsNet',
     'LyrDB',
     'LyricsDownload',
     'AZLyrics',
     'LyricsTime', # Solucionada :D
   # 'lyricsfly', # Ponerla que flipa. esta muy bien pero hay que hacerlo entero...
   # 'AstraWeb', # Da errores con el mechanize y la url (aburre)
   #  'Lyrics007', # Falla que te cagas
   #'Google', # Hace falta un google id
   #'Lyricscom', # la mia que no tira por ahroa
);
#}}}

##################################################
# Actual lyrics catching
###################################################{{{
our $lyrics;    # Lyrics as string (if any)
our $source;    # Source of the lyrics (if any)

&get_lyrics( $artist, $title );

# Catch lyrics for every source, until one yields a result
sub get_lyrics {
    my ($artist, $title) = @_;
    foreach my $site (@sources) {
        warn "Mirando en  $site!" if $DEBUG;
        $lyrics = Lyrics::Fetcher->fetch( $artist, $title, $site );
        #$lyrics = Lyrics::Fetcher::Cache->get( $artist, $title, $site );
        #$lyrics = Lyrics::Fetcher::Cache->set( $artist, $title, $site );
        if ($lyrics) {
            $source = $site;
            last;
        }
        warn "Nada en $site :(" if $DEBUG;
    }
}
#}}}

##################################################
# Heuristic stuff
###################################################{{{

# Try harder
if ($TRYHARD) {
    # Le quitamos el texto que se encuentra entre parentesis
    unless ($lyrics) { #title
        my($title_guess) = $title; 
        $title_guess =~ s/\(.*\)//;
        warn "Probando con : '$artist' => '$title_guess'" if $DEBUG;
        &get_lyrics( $artist, $title_guess );
    }
    # try it with every starting letter uppercase
    # (e.g. 'Law of Average' => 'Law Of Average')
    unless ($lyrics) { #title
        my $title_guess = &upcase_first( $title );
        warn "Probando con : '$title' => '$title_guess'" if $DEBUG;
        &get_lyrics( $artist, $title_guess );
    }
    unless ($lyrics) { #artist
        my $artist_guess = &upcase_first( $artist );
        warn "Probando con : '$artist' => '$artist_guess'" if $DEBUG;
        &get_lyrics( $artist_guess, $title );
    }
    unless ($lyrics) { #both
        my $artist_guess = &upcase_first( $artist );
        my $title_guess = &upcase_first( $title );
        warn "Probando con : '$artist' => '$artist_guess'" if $DEBUG;
        warn "Probando con : '$title' => '$title_guess'" if $DEBUG;
        &get_lyrics( $artist_guess, $title_guess );
    }

    # try it with every starting letter uppercase but making 
    # all other letters lowercase 
    # (e.g. 'LAW oF AVERAGE' => 'Law Of Average')
    unless ($lyrics) { #title
        my $title_guess = &upcase_first( lc($title) );
        warn "Probando con : '$title' => '$title_guess'" if $DEBUG;
        &get_lyrics( $artist, $title_guess );
    }
    unless ($lyrics) { #artist
        my $artist_guess = &upcase_first( lc($artist) );
        warn "Probando con : '$artist' => '$artist_guess'" if $DEBUG;
        &get_lyrics( $artist_guess, $title );
    }
    unless ($lyrics) { #both
        my $artist_guess = &upcase_first( lc($artist) );
        my $title_guess = &upcase_first( lc($title) );
        warn "Probando con : '$artist' => '$artist_guess'" if $DEBUG;
        warn "Probando con : '$title' => '$title_guess'" if $DEBUG;
        &get_lyrics( $artist_guess, $title_guess );
    }

    # try it with all-caps (i.e. 'ac/dc' => 'AC/DC')
    unless ($lyrics) { #title
        my $title_guess = uc($title);
        warn "Probando con : '$title' => '$title_guess'" if $DEBUG;
        &get_lyrics( $artist, $title_guess );
    }
    unless ($lyrics) { #artist
        my $artist_guess = uc($artist);
        warn "Probando con : '$artist' => '$artist_guess'" if $DEBUG;
        &get_lyrics( $artist_guess, $title );
    }
    unless ($lyrics) { #both
        my $artist_guess = uc($artist);
        my $title_guess = uc($title);
        warn "Probando con : '$artist' => '$artist_guess'" if $DEBUG;
        warn "Probando con : '$title' => '$title_guess'" if $DEBUG;
        &get_lyrics( $artist_guess, $title_guess );
    }
}
die "No lyrics found, sorry\n" unless $lyrics;

# Make first letter of every word in string uppercase
sub upcase_first {
    my $str = shift;
    my @tok_up = map(ucfirst, split(/ /, $str));
    my $str_up = join( ' ', @tok_up );
    return $str_up
}
#}}}

##################################################
# Formatting stuff
###################################################{{{
if ($HEADING) {
    my $header  = decode('utf8', "$artist - $title\n");
    $header .= "=" x length($header) . "\n";
    $lyrics = $header . $lyrics;
}

if ($SOURCE) {
    $lyrics .= "\n\n[ retrieved from $source ]\n";
}

if ($INDENT) {
    $lyrics = &indent( $lyrics );
    sub indent {
        my $lyrics = shift;
        my $prepend = ' ' x $INDENT;
        my $temp;
        foreach( split( "\n", $lyrics ) ) {
            s/^/$prepend/;
            $temp .= $_ . "\n";
        }
        return $temp;
    }
}
#}}}

open LESS, "|$PAGER";
print LESS $lyrics;
close LESS;

exit 0;
