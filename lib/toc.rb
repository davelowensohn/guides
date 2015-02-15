require 'redcarpet'
require 'pry'

module TOC
  class << self
    def registered(app)
      app.helpers Helpers
    end
    alias :included :registered
  end

  module TableOfContents
    extend self

    def anchorify(text)
      text.gsub(/&#?\w+;/, '-').gsub(/\W+/, '-').gsub(/^-|-$/, '').downcase
    end
  end

  module Helpers
    def toc_for(guides)
      buffer = "<ol id='toc-list'>"
      # indentation below is to aid in understanding the HTML structure
        guides.each do |guide|
          next if guide.chapters.any? do |entry|
            entry[:skip_sidebar]
          end

          slugs = request.path.split('/')

          requested_guide_url = slugs[0]
          current = (guide.url == requested_guide_url)

          middleman_url = "/#{guide.url}/#{guide.chapters[0].url}.html"

          buffer << "<li class='level-1 #{current ? 'selected' : ''}'>"
            buffer << link_to(guide.title, middleman_url)
            buffer << "<ol class='#{(current ? 'selected' : '')}'>"
              guide.chapters.each do |chapter|
                next if chapter[:skip_sidebar_item]
                url = "#{guide.url}/#{chapter.url}.html"

                sub_current = (url == current_page.path)

                middleman_url = "/" + url

                buffer << "<li class='level-3 #{sub_current ? ' sub-selected' : ''}'>"
                  buffer << link_to(chapter.title, middleman_url)
                buffer << "</li>"
              end
            buffer << "</ol>"
          buffer << "</li>"
        end

      buffer << "</ol>"
      buffer
    end

    def guide_name
      current_guide.name if current_guide
    end

    def chapter_name
      if current_chapter
        return current_chapter.title
      else
        return ""
      end
    end

    def chapter_heading
      name = chapter_name.strip
      return if name.blank?

      %Q{
        <h1>
          #{name}
          <a href="#{chapter_github_source_url}" target="_blank" class="edit-page icon-pencil">Edit Page</a>
        </h1>
      }
    end

    def guide_slug
      request.path.split('/')[0]
    end

    def chapter_slug
      request.path.split('/')[0..-2].join('/')
    end

    def chapter_github_source_url
      base_guide_url = "https://github.com/emberjs/website/tree/master/source/guides"
      if guide_slug == chapter_slug
        return "#{base_guide_url}/#{current_chapter['url']}/index.md"
      else
        return "#{base_guide_url}/#{current_chapter['url'].gsub(/.html/, '')}.md"
      end
    end

    def current_guide
      return @current_guide if @current_guide

      path = current_page.path.gsub('.html', '')
      guide_path = path.split("/")[0]

      @current_guide = data.guides.find do |guide|
        guide.url == guide_path
      end
    end

    def current_chapter
      return unless current_guide

      return @current_chapter if @current_chapter
      path = current_page.path.gsub('.html', '')
      chapter_path = path.split('/')[1..-1].join('/')

      @current_chapter = current_guide.chapters.find do |chapter|
        chapter.url == chapter_path
      end
    end

    def chapter_links
      %Q{
      <footer>
        #{previous_chapter_link} #{next_chapter_link}
      </footer>
      }
    end

    def previous_chapter_link
      options = {:class => 'previous-guide'}

      if previous_chapter
        url = "/#{current_guide.url}/#{previous_chapter.url}.html"
        title = " \u2190 #{previous_chapter.title}"

        link_to(title, url, options)
      elsif whats_before = previous_guide
        previous_chapter = whats_before.chapters.last

        url = "/#{previous_guide.url}/#{previous_chapter.url}.html"
        title = " \u2190 #{previous_chapter.title}"

        link_to(title, url, options)
      else
        ''
      end
    end

    def next_chapter_link
      options = {:class => 'next-guide'}

      if next_chapter
        url = "/#{current_guide.url}/#{next_chapter.url}.html"
        title = "#{next_chapter.title} \u2192"

        link_to(title, url, options)
      elsif whats_next = next_guide
        next_chapter = whats_next.chapters.first
        title = "We're done with #{current_guide.title}. Next up: #{next_guide.title} - #{next_chapter.title} \u2192"
        url = "/#{next_guide.url}/#{next_chapter.url}.html"

        link_to(title, url, options)
      else
        ''
      end
    end

    def previous_chapter
      return unless current_guide

      current_chapter_index = current_guide.chapters.find_index(current_chapter)

      return unless current_chapter_index

      previous_chapter_index = current_chapter_index - 1

      if current_chapter_index > 0
        current_guide.chapters[previous_chapter_index]
      else
        nil
      end
    end

    def next_chapter
      return unless current_guide

      current_chapter_index = current_guide.chapters.find_index(current_chapter)
      return unless current_chapter_index

      next_chapter_index = current_chapter_index + 1

      if current_chapter_index < current_guide.chapters.length
        current_guide.chapters[next_chapter_index]
      else
        nil
      end
    end

    def previous_guide
      return unless current_guide

      current_guide_index = data.guides.find_index(current_guide)
      return unless current_guide_index

      previous_guide_index = current_guide_index - 1

      if previous_guide_index >= 0
        data.guides[previous_guide_index]
      else
        nil
      end
    end

    def next_guide
      return unless current_guide

      current_guide_index = data.guides.find_index(current_guide)
      return unless current_guide_index

      next_guide_index = current_guide_index + 1

      if current_guide_index < data.guides.length
        data.guides[next_guide_index]
      else
        nil
      end
    end

    def warning
      return unless current_chapter
      return unless current_guide
      warning_key = current_chapter["warning"]
      warning_key ? WARNINGS[warning_key] : nil
    end


    WARNINGS = {
        "canary"=>  %Q{
          <div class="under_construction_warning">
            <h3>
              <div class="msg">
                WARNING: this guide refers to a feature only available in canary (nightly/unstable) builds of Ember.js.
              </div>
            </h3>
          </div>
        },
        "canary-data"=>  %Q{
          <div class="under_construction_warning">
            <h3>
              <div class="msg">
                WARNING: this guide refers to a feature only available in canary (nightly/unstable) builds of Ember Data.
              </div>
            </h3>
          </div>
        }
    }

  end
end

::Middleman::Extensions.register(:toc, TOC)