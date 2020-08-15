module DuckCheck
  class NonconformanceError < StandardError
    def self.for_infringements(infringements)
      new("\n\n" + <<~END_MESSAGE + "\n\n")
        #{"====[ #{self} ]".ljust(70, '=')}

        Incompatibilities were detected between some implementations and their
        declared interfaces:

        #{infringements.map { "  - #{_1}" }.join("\n\n")}

        #{'='*70}
      END_MESSAGE
    end
  end
end
