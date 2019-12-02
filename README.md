# Airtable

Simple crystal library for interacting with Airtable API with builtin caching

## Installation

1. Add the dependency to your `shard.yml`:

   ```yaml
   dependencies:
     airtable:
       github: mang/airtable
   ```

2. Run `shards install`

## Usage

   ```crystal
   require "airtable"
   ```

Go to https://airtable.com/account to generate api keys, then
https://airtable.com/api to the api documentation for your base.

### Configure Airtable with:
   ```crystal
   Airtable.config.api_key = <your_api_key>
   Airtable.config.base_name = <your_base_name>
   ```
### Define models
Then you need to define models for your tables. Create a class inherited
from `Airtable::Model`, like

   ```crystal
   class BlogPost < Airtable::Model

     # Creates utility classes for working with the model like
     # BlogPost::Record and BlogPost::Record::List.
     # Pass the name of the table in Airtable
     def_wrappers("blog_posts")

     # Define the columns of the table (see API documentation).
     JSON.mapping(
       title: String?,
       body: String?,
       comments: Array(BlogPost::Comment)?,
       tags: Array(Tag)?,
       images: Array(Airtable::Image)?,
       status: String?,
       url: String?
     )

   end
   ```

#### Query Airtable
Use #list or #show to query
   ```crystal
   blog_posts = BlogPost.list(
     filterByFormula: %{{status} = "published"}
   )

   blog_post = BlogPost.show(#{airtable_row_id})
   ```

#### Relations
Access linked entires from foreign tables by querying them with the row ID
   ```crystal
   class BlogPost::Comment < Airtable::Model
     def_wrappers("blog_post_comments")

     # Define the columns of the table (see API documentation).
     JSON.mapping(
       blog_post: String?
       author: String?,
       body: String?,
     )

   end

   post_comments = BlogPost::Comment.list(
     filterByFormula: %{ {blog_post} = "#{blog_post.id}" },
   )
   ```

#### Use your models
   ```crystal
   blog_posts.each do |blog_post|

     # Access post Airtable ID
     blog_post.id

     # Access post column values
     blog_post.fields.title
     blog_post.fields.description

   end
   ```

#### Save your entries
   ```crystal
   # Create a new entry
   blog_post = BlogPost.create(
     title: "A new blog post",
     body: "Awesome blog post goes here",
     status: "Draft"
   )

   # Add a foreign relation
   tag = Tag.show("tutorial")
   blog_post.fields.tags.push(tag.id)
   blog_post.save
   ```

#### Images in airtable
You'll probably want to use a macro or helper function for this.
   ```crystal
   blog_post.fields.images do |image|
     image.thumbnails.as(Airtable::ImageThumbnailList).small.as(Airtable::ImageThumbnail).url
     image.thumbnails.as(Airtable::ImageThumbnailList).large.as(Airtable::ImageThumbnail).url
     image.thumbnails.as(Airtable::ImageThumbnailList).full.as(Airtable::ImageThumbnail).url
   end
   ```
   
#### Cache and limits
Airtable API has a limit of 5 req/s (and response times sometimes aren't
great). You could use a caching proxy, but airtable also has builtin
caching. By default, records are cached, and subsequent requests are read
from cache. You can override this by passing the `source` param to #show or #list
like this:

   ```crystal
   blog_posts = BlogPost.list(
     filterByFormula: %{{status} = "published"},
     source: :backend # default is :cache
   )
   ```

Cache is refreshed on entry update.

## Configuration
   ```crystal
   # set api key
   Airtable.config.api_key = <your_api_key>

   # set base name
   Airtable.config.base_name = <your_base_name>

   # enable debugging
   Airtable.config.debug = true

   # set cache expiration times
   Airtable.config.cache = CacheHash(String).new(30.days),
   ```

## TODO
- Delete records

## Development

TODO: Write development instructions here

## Contributing

1. Fork it (<https://github.com/mang/airtable/fork>)
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request

## Contributors

- [maggie](https://github.com/mang) - creator and maintainer
