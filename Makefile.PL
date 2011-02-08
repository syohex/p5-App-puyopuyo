use inc::Module::Install;
use Module::Install::AuthorTests;
use Module::Install::ReadmeMarkdownFromPod;

all_from 'lib/App/puyopuyo.pm';
readme_markdown_from('lib/App/puyopuyo.pm');

test_requires 'Test::More' => 0.88;
test_requires 'Test::Requires';

auto_set_repository();
WriteAll;