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
        builder = DuckCheck.self_implementors_of(ITokenBuilder).find do
          scanner.match?(_1.pattern)
        end

        if builder
          match = scanner.scan(builder.pattern)
          builder.token_for(match)
        else
          raise Parser::Error, "Unrecognised token at: #{scanner.rest}"
        end
      end

      module IToken
        # @returns [String] A developer-readable representation of the token
        def inspect; end
      end

      module IAstBuilder
        # Incorporates the token into the given parser AST node stack by
        # mutating it.
        #
        # @param stack [Array[INode]] The parser AST node stack
        def build_node!(stack); end
      end

      module ITokenBuilder
        # @returns [Regexp] A pattern for matching the token strings
        def pattern; end

        # Builds a token from a string that matches PATTERN
        #
        # @returns [IToken] the token
        def token_for(match); end
      end

      module IOperator
        # @returns [Integer] a number representing relative operator precedence
        def precedence; end
      end

      class Hashtag
        self_implements ITokenBuilder
        implements IToken, IAstBuilder

        def self.pattern
          Zettel::Doc::HASHTAG_REGEX_IGNORING_PRECEDING
        end

        def self.token_for(match)
          new(name: match.delete_prefix('#'))
        end

        value_semantics do
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
        extend self
        self_implements ITokenBuilder
        implements IToken, IAstBuilder, IOperator

        def pattern
          /!|not/i
        end

        def token_for(_); self; end

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
        extend self
        self_implements ITokenBuilder
        implements IToken, IAstBuilder, IOperator

        def pattern
          /&&?|and/i
        end

        def token_for(_); self; end

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
        extend self
        self_implements ITokenBuilder
        implements IToken, IAstBuilder, IOperator

        def pattern
          /\|\|?|or/i
        end

        def token_for(_); self; end

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
        extend self
        self_implements ITokenBuilder
        implements IToken, IOperator

        def pattern
          /\(/
        end

        def token_for(_); self; end

        def precedence
          PREC_NONE
        end

        def inspect
          'Token[(]'
        end
      end

      module CloseParen
        extend self
        # not IOperator, because it doesn't act like one. It has special
        # behaviour in the tokenizer.
        self_implements ITokenBuilder
        implements IToken

        def pattern
          /\)/
        end

        def token_for(_); self; end

        def inspect
          'Token[)]'
        end
      end
    end

    module AST
      module INode
        # @param hashtag_set [Enumerable] a collection of hashtag names
        # @returns [Boolean]
        def match?(hashtag_set); end

        # @returns [String] a human-readable representation of the node
        def to_s; end
      end

      class Hashtag
        implements INode

        value_semantics do
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
        implements INode

        value_semantics do
          subnode # INode
        end

        def match?(set)
          not subnode.match?(set)
        end

        def to_s
          "(NOT #{subnode})"
        end
      end

      class And
        implements INode

        value_semantics do
          subnodes Array # Of(INode)
        end

        def match?(set)
          subnodes.all? { _1.match?(set) }
        end

        def to_s
          '(' + subnodes.join(' AND ') + ')'
        end
      end

      class Or
        implements INode

        value_semantics do
          subnodes Array # Of(INode)
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
