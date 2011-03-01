module BHM
  module GoogleMaps

    DEFAULT_WIDTH = 540
    DEFAULT_HEIGHT = 400
    DEFAULT_SIZE = "#{DEFAULT_WIDTH}x#{DEFAULT_HEIGHT}"

    class Location
      def initialize(attributes)
        attributes.each do |k, v|
          instance_variable_set :"@#{k}", v
        end
      end
      attr_reader :lat, :lng, :address, :color, :size, :icon

      # Convert an object to a Location
      # An object should implement a method `to_gmap_data` that returns a hash of 
      # location and style data.
      #
      # For simple cases where custom styles aren't needed, a class just needs to 
      # implement `lat` and `lng` methods.
      def self.from(location)
        if location.respond_to? :to_gmap_data
          new(location.to_gmap_data) 
        else
          new({:lat => location.lat, :lng => location.lng })
        end
      end
    end


    class Builder
      def initialize(template, addresses, options)
        @template = template
        @addresses  = Array.wrap(addresses).map {|l| Location.from(l) }
        @options  = options.symbolize_keys
        @marker_options = @options.delete(:marker) || {}
        @static = @options.delete(:static)
        @width, @height, @size = determine_size(options)
        css_class = "#{BHM::GoogleMaps.container_class} #{BHM::GoogleMaps.static_map_class} #{@options.delete(:class)}"
        @container_html_options = {
          :class => css_class,
          :style => "width: #{@width}px; height: #{@height}px"
        }
      end

      def determine_size(options)
        size = options.delete(:size) || DEFAULT_SIZE
        w, h = size.split('x')
        return w, h, size
      end

      def to_html
        image = build_static_map
        @static ? image :  build_container(image) 
      end

      def build_static_map
        url = StaticMap.new(@addresses, @marker_options.merge(@options||{})).to_url
        options = {:alt => alt_text}.merge(@options||{})
        @template.image_tag(url, options)
      end
      
      def build_container(image)
        if selector = @options.delete(:location_data_selector)
          # Lat/Lng data is embedded elsewhere in the page
          container_html_options[:'data-locations-selector'] = selector
        elsif @addresses.length == 1
          embed_location_data_for_location
        else
          embed_location_data_for_locations
        end

        #Pass along users html options
        #container_html_options.reverse_merge!(@options)
        @template.content_tag(:div, image, @container_html_options)
      end
    
      def embed_location_data_for_location
        lat, lng = @addresses.first.lat, @addresses.first.lng
        @container_html_options.merge! 'data-latitude' => lat, 'data-longitude' => lng
        #@marker_options[:title] ||= self.address_as_string
        @marker_options.each_pair do |k, v|
          @container_html_options[:"data-marker-#{k.to_s.dasherize}"] = v
        end                                    
      end

      def embed_location_data_for_locations
        latitudes, longitudes = [], []
        @addresses.each do |address|
          latitudes << address.lat
          longitudes << address.lng
        end
        @container_html_options.merge!(
          'data-latitude' => latitudes.join(', '),
          'data-longitude' => longitudes.join(', ')
        )
        #@marker_options[:title] ||= self.address_as_string
        #@marker_options.each_pair do |k, v|
          #container_html_options[:"data-marker-#{k.to_s.dasherize}"] = v
        #end                                    
      end
      

      def alt_text
        if (count = @addresses.length) > 1
          @template.pluralize(count, "address") + " plotted on a map"
        else
          BHM::GoogleMaps.address_to_s_proc.call(@addresses.first)
        end
      end 

    end
  end
end
