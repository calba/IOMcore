use ExtUtils::MakeMaker;

WriteMakefile(
  NAME         => 'IOMCore',
  VERSION_FROM => 'lib/IOMCore.pm',
  
  META_MERGE   => {
                  'meta-spec' => { version => 2 },
                  resources   => {
                           repository => {
                             type => 'git',
                             url => 'https://github.com/calba/IOMcore.git',
                             web => 'https://github.com/calba/IOMcore',
                           },
                  },
  },
  EXE_FILES    => [ qw( script/fichConfTool.pl ) ],
);

