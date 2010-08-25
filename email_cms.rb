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

get '/delete' do
  Post.destroy_all
  'Deleted all posts'
end

post '/incoming_message/' do
  message = Mail.new(params[:message])
  
  if message.multipart?
    attachments = []
    body = ""
    
    message.parts.each do |part|
      if part.content_type =~ /^text\/plain/i
        body << part.body.decoded
      elsif part.attachment?
        @grid ||= Mongo::Grid::new(Mongoid.database)
        file = @grid.put(part.body.decoded)
        attachments << Attachment.new(:grid_id => file)
      end
    end
    
    @post = Post.create!(:title => message.subject, :body => body, :attachments => attachments)
  else
    @post = Post.create!(:title => message.subject, :body => message.body.decoded)
  end
  
  haml :post
end

get '/images/:id' do
  grid = Mongo::Grid::new(Mongoid.database)
  grid.get(BSON::ObjectID.from_string(params[:id])).read
end

class Post
  include Mongoid::Document
  field :title
  field :body
  embeds_many :attachments
end

class Attachment
  include Mongoid::Document
  
  field :grid_id
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
        - for attachment in post.attachments do
          %img{:src => "/images/#{attachment.grid_id}"}
@@post
%h1= @post.title
#content
  = @post.body