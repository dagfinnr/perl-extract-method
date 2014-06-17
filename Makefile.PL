use ExtUtils::MakeMaker;

WriteMakefile(
	'NAME'          => 'PPIx::EditorTools::ExtractMethod',
	'VERSION_FROM'  => 'lib/PPIx/EditorTools/ExtractMethod.pm',
	'LICENSE'       => 'perl',
	'META_MERGE'    => {
		resources => {
			repository  =>  'https://github.com/dagfinnr/perl-extract-method',
		},
	},
	'PREREQ_PM'  => {
		'PPIx::EditorTools' => 0.08,
		'App::EditorTools'  => 0,
		'Moose'             => 0,
		'Params::Coerce'    => 0,
		'aliased'           => 0,
		'Set::Scalar'       => 0,
		'Test::More'        => 0.98, # make sure we have subtest support
	},
);
