context DiffParser do
  test "parses diffs" do
    actual = DiffParser.parse(<<~END_DIFF)
      diff --git a/builtin-http-fetch.c b/http-fetch.c
      index f3e63d7..e8f44ba 100644
      --- a/builtin-http-fetch.c
      +++ b/http-fetch.c
      @@ -1 +1 @@
      -#include "cache.h"
      +#include "cache.hpp"
      @@ -18,6 +19,8 @@ int cmd_http_fetch(int argc, const char **argv, ...

      -int cmd_http_fetch(int argc, const char **argv, const char *prefix)
      +int main(int argc, const char **argv)
       {
      +       const char *prefix;
              struct walker *walker;
      diff --git a/whatever.png b/whatever.png
      Binary files a/whatever.png and b/whatever.png differ
    END_DIFF

    expected = [
      DiffParser::File.new(
        headers: ['index f3e63d7..e8f44ba 100644'],
        source: 'a/builtin-http-fetch.c',
        destination: 'b/http-fetch.c',
        hunks: [
          DiffParser::Hunk.new(
            source_range: 1...2,
            destination_range: 1...2,
            context: '',
            lines: [
              DiffParser::Line.removed('#include "cache.h"'),
              DiffParser::Line.added('#include "cache.hpp"'),
            ]
          ),
          DiffParser::Hunk.new(
            source_range: 18...24,
            destination_range: 19...27,
            context: 'int cmd_http_fetch(int argc, const char **argv, ...',
            lines: [
              DiffParser::Line.same(''),
              DiffParser::Line.removed('int cmd_http_fetch(int argc, const char **argv, const char *prefix)'),
              DiffParser::Line.added('int main(int argc, const char **argv)'),
              DiffParser::Line.same('{'),
              DiffParser::Line.added('       const char *prefix;'),
              DiffParser::Line.same('       struct walker *walker;'),
            ]
          )
        ]
      ),
      DiffParser::File.new(
        headers: [],
        source: 'a/whatever.png',
        destination: 'b/whatever.png',
        hunks: [],
      )
    ]

    assert_eq(actual, expected)
  end
end
