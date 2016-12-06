use ExtUtils::MakeMaker;

WriteMakefile(
  NAME         => 'IOMCore',
  AUTHOR => 'ols@apdo.com',
  VERSION_FROM => 'lib/IOMCore_Version.pm',
  
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

