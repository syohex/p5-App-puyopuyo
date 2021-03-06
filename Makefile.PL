use inc::Module::Install;
use Module::Install::AuthorTests;
use Module::Install::ReadmeMarkdownFromPod;

all_from 'lib/App/puyopuyo.pm';
readme_markdown_from('lib/App/puyopuyo.pm');

requires 'Term::ANSIColor';

test_requires 'Test::More' => 0.88;
test_requires 'Test::Exception';

recommends 'Data::Section::Simple';

auto_set_repository();
WriteAll;
