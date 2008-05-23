# PermalinkFu

A simple plugin for creating URL-friendly permalinks (slugs) from attributes.


## Dependencies

Uses the the [`unicode` library](http://www.yoshidam.net/Ruby.html) (`gem install unicode`) to get around [platform inconsistencies](http://blade.nagaokaut.ac.jp/cgi-bin/scat.rb/ruby/ruby-talk/243426) with `iconv`.


## Usage

    class Article < ActiveRecord::Base
      has_permalink :title
    end

This will escape the title in a before_validation callback, turning e.g. "Föö!! Bàr" into "foo-bar".

The permalink is by default stored in the `permalink` attribute.

    has_permalink :title, :slug
  
will store it in `slug` instead.

    has_permalink [:category, :title]
  
will store a permalink form of `"#{category}-#{title}"`.

Permalinks are guaranteed unique: "foo-bar-2", "foo-bar-3" etc are used if there are conflicts. You can set the scope of the uniqueness like

    has_permalink :title, :scope => :blog_id

This means that two articles with the same `blog_id` can not have the same permalink, but two articles with different `blog_id`s can.

You can add conditions to `has_permalink` like so:

  	class Article < ActiveRecord::Base
  	  has_permalink :title, :if => Proc.new { |article| article.needs_permalink? }
  	end

Use the `:if` or `:unless` options to specify a Proc, method, or string to be called or evaluated. The permalink will only be generated if the option evaluates to true.

You can use `PermalinkFu.escape` to escape a string manually.


## Credits

Originally extracted from [Mephisto](http://mephistoblog.com) by [technoweenie](http://github.com/technoweenie/permalink_fu/).

Conditions added by [Pat Nakajima](http://github.com/nakajima/permalink_fu/).

[Henrik Nyh](http://github.com/technoweenie/permalink_fu/) made minor fixes and swapped `iconv` for the [slugalizer](http://github.com/henrik/slugalizer) library, originally by [Christoffer Sawicki](http://termos.vemod.net).
