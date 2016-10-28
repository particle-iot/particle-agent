require "highline"

module ParticlePi
  class ColorScheme < HighLine::ColorScheme
    def initialize
      if use_color?
        super(color_scheme)
      else
        super(blank_scheme)
      end
    end

    def use_color?
      $stdout.tty?
    end

    def color_scheme
      {
        title:     [:cyan, :bold],
        link:      [:blue, :bold],
        highlight: [:yellow, :bold],
        error:     [:red, :bright],
      }
    end

    def blank_scheme
      {
        title: [],
        link: [],
        highlight: [],
        error: [],
      }
    end
  end
end
