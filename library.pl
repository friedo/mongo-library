use Mojolicious::Lite;
use MongoDB;

get '/' => sub { 
    my $self = shift;
    $self->render( text => 'Hello, library users!' );   
};

get '/books' => sub { 
    my $self   = shift;
    my $mongo  = MongoDB::MongoClient->new;  # localhost by default
    my $db     = $mongo->get_database( 'library' );
    my $coll   = $db->get_collection( 'books' );
    my $cursor = $coll->find;                # finds everything

    $self->render( 'books', books_cursor => $cursor, db => $db );
};

post '/books' => sub { 
    my $self   = shift;
    my $mongo  = MongoDB::MongoClient->new;

    my $new_book = { title   => scalar $self->param( 'title' ),
                     author  => scalar $self->param( 'author' ),
                     genre   => [ $self->param( 'genre' ) ],
                     publication => { 
                         name     => scalar $self->param( 'pub_name' ),
                         location => scalar $self->param( 'pub_location' ),
                         date     => DateTime->new( 
                             month => scalar $self->param( 'pub_month' ),
                             year  => scalar $self->param( 'pub_year' )
                         )
                     }
                   };

    $mongo->get_database( 'library' )
      ->get_collection( 'books' )->insert( $new_book );
};

get '/books/:genre' => sub { 
    my $self   = shift;
    my $genre  = $self->stash( 'genre' );

    my $mongo  = MongoDB::MongoClient->new;
    my $cursor = $mongo->get_database( 'library' )
      ->get_collection( 'books' )
        ->find( { genre => $genre } );

    $self->render( 'books', books_cursor => $cursor, db => $mongo->get_database( 'library' ) );
};

app->start;

__DATA__
@@ books.html.ep
<h1>Here is your list of books!</h1>
<ul>
<% while( my $doc = $books_cursor->next ) {  %>
<%   my $author = $db->get_collection( 'authors' )->find_one( { _id => $doc->{author} } ); %>
<li><%= $doc->{title} %> by <a href="/author/<%= $author->{slug} %>">
      <%= $author->{first_name} %> <%= $author->{last_name} %>
</a></li>y
<% } %>
</ul>


