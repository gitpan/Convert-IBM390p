use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'	=> 'Convert::IBM390p',
    'VERSION_FROM' => 'IBM390p.pm', # finds $VERSION
    'dist'	=> { COMPRESS=>'gzip' },
);
