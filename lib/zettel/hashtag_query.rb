class Zettel::HashtagQuery
  def self.parse(text)
    Parser.(text)
  end

  private

    module Parser
      class Error < StandardError; end

      extend self

      def call(text)
        parser_stack = []

        tokenize(text)
          .then { reverse_polish_notation(_1) }
          .each { _1.build_node!(parser_stack) }

        if parser_stack.size == 1
          parser_stack.first
        else
          raise Parser::Error, "Parsing failed. Remaining stack:\n\n#{parser_stack.inspect}"
        end
      end

      # shunting yard algorithm
      def reverse_polish_notation(tokens)
        output = []
        stack = []

        tokens.each do |tok|
          case tok
          when Tokens::Hashtag
            output << tok
          when Tokens::OpenParen
            stack << tok
          when Tokens::CloseParen
            while stack.last != Tokens::OpenParen
              if stack.size > 0
                output << stack.pop!
              else
                raise Parser::Error, "Unmatched closing parenthesis"
              end
            end
            stack.pop! # remove open paren
          else # operator token
            while stack.any? && stack.last.precedence >= tok.precedence
              output << stack.pop! # pop off higher precedence operations
            end
            stack << tok
          end
        end

        # pop all remaning operators to output
        output + stack.reverse
      end

      def tokenize(text)
        scanner = StringScanner.new(text)
        [].tap do |results|
          loop do
            scanner.skip(/\s+/)
            break if scanner.eos?
            results << Tokens.next(scanner)
          end
        end
      end

    end

    module Tokens
      #precedence
      PREC_NONE = 0
      PREC_BINARY = 1
      PREC_UNARY = 2

      def self.next(scanner)
        builder =
          [Hashtag, And, Or, Not, OpenParen, CloseParen]
            .find { scanner.match?(_1::PATTERN) }

        if builder
          match = scanner.scan(builder::PATTERN)
          builder.for(match)
        else
          raise Parser::Error, "Unrecognised token at: #{scanner.rest}"
        end
      end

      class Hashtag
        PATTERN = Zettel::Doc::HASHTAG_REGEX_IGNORING_PRECEDING

        def self.for(match)
          new(name: match.delete_prefix('#'))
        end

        value_attrs do
          name String
        end

        def build_node!(stack)
          stack << AST::Hashtag.new(name: name)
        end

        def inspect
          'Token[#' + name + ']'
        end
      end

      module Not
        PATTERN = /!|not/i

        extend self
        def for(_); self; end

        def precedence
          PREC_UNARY
        end

        def build_node!(stack)
          subnode = stack.pop!
          stack.push(AST::Not.new(subnode: subnode))
        end

        def inspect
          'Token[NOT]'
        end
      end

      module And
        PATTERN = /&&?|and/i

        extend self
        def for(_); self; end

        def precedence
          PREC_BINARY
        end

        def build_node!(stack)
          right = stack.pop!
          left = stack.pop!
          stack.push(AST::And.new(subnodes: [left, right]))
        end

        def inspect
          'Token[AND]'
        end
      end

      module Or
        PATTERN = /\|\|?|or/i

        extend self
        def for(_); self; end

        def precedence
          PREC_BINARY
        end

        def build_node!(stack)
          right = stack.pop!
          left = stack.pop!
          stack.push(AST::Or.new(subnodes: [left, right]))
        end

        def inspect
          'Token[Or]'
        end
      end

      module OpenParen
        PATTERN = '('

        def precedence
          PREC_NONE
        end

        extend self
        def for(_); self; end

        def inspect
          'Token[(]'
        end
      end

      module CloseParen
        PATTERN = ')'

        extend self
        def for(_); self; end

        def inspect
          'Token[)]'
        end
      end
    end

    module AST
      class Hashtag
        value_attrs do
          name String
        end

        def match?(set)
          set.include?(name)
        end

        def to_s
          '#' + name
        end
      end

      class Not
        value_attrs do
          subnode # Node
        end

        def match?(set)
          not subnode.match?(set)
        end

        def to_s
          "(NOT #{subnode})"
        end
      end

      class And
        value_attrs do
          subnodes Array # Of(Node)
        end

        def match?(set)
          subnodes.all? { _1.match?(set) }
        end

        def to_s
          '(' + subnodes.join(' AND ') + ')'
        end
      end

      class Or
        value_attrs do
          subnodes Array # Of(Node)
        end

        def match?(set)
          subnodes.any? { _1.match?(set) }
        end

        def to_s
          '(' + subnodes.join(' OR ') + ')'
        end
      end
    end
end
