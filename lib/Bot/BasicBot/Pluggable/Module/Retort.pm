package Bot::BasicBot::Pluggable::Module::Retort;

use strict;
use warnings;

use Bot::BasicBot::Pluggable::Module;
use base 'Bot::BasicBot::Pluggable::Module';

use Bot::BasicBot::Pluggable::Store;
use Text::English;

our $VERSION = '1.000000';

my $store = Bot::BasicBot::Pluggable::Store->new( 'option' => 'value' );
my $sns   = 'Retort', 

my %awesomes = (
    'cache' => [
        'Caching?  Implement it!',
        'Yeah, we totally need some caching that.',
        'I read if you cache your caching layer, it\'s awesome.',
        'What if we cached our already cached mason objects?  Would we be 1337 then?',
    ],
    'touch' => [
        'heh, that\'s what she said.',
        'Please don\'t touch me there.',
        'Hey! That\'s my naughty place!',
        '. o O!  That\'s where my 1st grade teacher used to touch me, too.  Memories.',
    ],
    'finger' => [
        'http://is.gd/xRW1',
        'http://is.gd/rwMl',
        'heh, that\'s what she said.',
        ' ... in the bedroom.',
    ],
    'beer' => [
        'Beer?  Where?',
        'Mmmmm.... Beeeeer.',
    ],
);

foreach my $wurd ( keys %awesomes ) {
    $store->set( $sns, 'phrases', \%awesomes )
        if ( ! $store->get( $sns, 'phrases' ) );
}

sub help {
    return 'retort [WORD] as [STATEMENT]' 
}

sub _get_phrases {
    my ($self, $word) = @_;
    if ($word){
        my ( $stem ) = Text::English::stem(lc($word));
        return $store->get( $sns, 'phrases' )->{$stem};
    }else{
        return $store->get( $sns, 'phrases' );
    }
}

sub _set_phrases {
    my ($self, $word, $phrases) = @_;
    my ( $stem ) = Text::English::stem(lc($word));
    my $all_phrases = $store->get( $sns, 'phrases' );
    $all_phrases->{$stem} = $phrases;
    $store->set( $sns, 'phrases', $all_phrases );
    $store->save;
}

sub said {
    my ( $self, $args, $pri ) = @_;
    my ( $who, $nick, $channel, $body, $address ) = 
        @$args{ qw( who nick channel body address ) };

    return unless ( $pri == 2 ); 

    if ( $body =~ /^.*remove retort (\w+) as (.*)$/ ) {
        my $i = my $found = 0;
        my $has = $self->_get_phrases($1);
        for my $phrase (@$has){
            if(lc($phrase) eq lc($2)){
                $found = 1;
                splice(@$has, $i, 1);
            }
            $i++;
        }
        if($found){
            $self->_set_phrases( $1, $has );
            return "$who, ok, removed.";
        }
        return "$who, not found!";
    } elsif ( $body =~ /.*list retort\s*(\w+)?/i ) {
        my $message;
        my $phrases = $self->_get_phrases;
        if($1){
            if (my $has = $self->_get_phrases($1)){
                $message .= "$1: "; 
                $message .= "\n\t$_" for (@$has);
            }
        }else{
            $message .=  "$_ " for (keys $phrases);
        }
        return $message ||= "No retorts found for $1.";
    }elsif ( $body =~ /^.*retort (\w+) as (.*)$/ ) {
        my ( $word, $content ) = ( $1, $2 );
        my $has = $self->_get_phrases($word);
        push( @{ $has ||= [] }, $content );
        $self->_set_phrases($word, $has);
        
        $self->reply( $args, "$who, got it." ); 
        return;
    }

    foreach my $stem (Text::English::stem(map{ lc } split( /\s+/, $body))){
        if ( my $has = $self->_get_phrases($stem) ) {
            $self->reply( $args, $has->[ int( rand( @$has ) ) ] );
            return;
        }
    }
}

1;

__END__

=pod

=head1 NAME 

Bot::BasicBot::Pluggable::Module::Retort - Witty statements and replies to English word stems.

=head1 DESCRIPTION

Will interpret IRC comments, find the roots of each word stated (using the Porter stemming algorithm as
implemented by L<Text::English>) and reply with a random witty statement defined by the users in the group.

    anon: I touched the file
    anon: bot, retort touch as heh, that's what she said.
    anon: I touched the file
    bot: heh, that's what she said

Where 'touch' is a root term for 'touched', 'touching', etc.  Where the bot will translate all retort memory
commands and statements into their root for canonicalization sakes.

=head1 IRC INTERFACE

=over 4

=item retort <term> as <statement>

Will take the root of "term" and, effectively, push the "statement" onto the known list for the particular "term".

=item General channel discussions 

Will find the roots of each of the words in each of the statements, matching them against the list of known
terms to retort upon.  If one is found, will choose an random statement from the list and say it.  If more
than one root in the statement is linked to a term, it will only say the first and ignore the rest of the 
statement's roots.

=back

=cut
