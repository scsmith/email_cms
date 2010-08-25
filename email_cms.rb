require 'sinatra'
require 'haml'
require 'mongoid'
require 'sinatra/mongoid'
require 'mail'

get '/' do
  @posts = Post.all
  haml :posts
end

get '/:id' do
  @post = Post.first(:conditions => {:id => params[:id]})
  pass if @post.nil?
  haml :post
end

post '/incoming_message/' do
  message = Mail.new(params[:message])
  
  @post = Post.create!(:title => message.subject, :body => message.body.decoded)
  haml :post
end

class Post
  include Mongoid::Document
  field :title
  field :body
end

__END__

@@layout
%html
  %head
  %body
    =yield

@@posts
%h1 Posts
#posts
  - for post in @posts
    #post
      %h2
        %a{:href => "/#{post.id}"}= post.title
      #content
        = post.body
    
@@post
%h1= @post.title
#content
  = @post.body