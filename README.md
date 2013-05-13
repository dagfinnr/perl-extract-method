perl-extract-method
===================

A serious attempt to get serious refactoring tool support for Perl code.

How to try it
-------------

Not working yet in this version.
<!---
1. Install PPIx::EditorTools and App::EditorTools from CPAN.
2. Clone the repository.
3. Add the lib directory to your Perl include path.
4. Copy `share/extract_method.vim` to `ftplugin/perl` in your vim directory.
-->

What
----

The theory and practice of refactoring has been extensively documented by
Martin Fowler. Refactoring is a set of specific procedures to improve the
design of existing code, and [Extract
Method](http://sourcemaking.com/refactoring/extract-method) is arguably the
most important of these.

The goal
--------

I'm aiming for a safe refactoring. In other words, the ability to do
a an automatic, fully behavior-preserving transformation of the code. 
I don't expect this to happen in 100% of cases, but perhaps 99% is achievable.

Why safe refactoring
--------------------

A safe, automated refactoring process is worth having for at least two reasons. In
"normal" circumstances with reasonably clean code that has good test coverage,
it's just faster than a manual refactoring. Manual refactoring is relatively
quick when you're used to it and when it works. But sometimes you get weird,
unexpected errors, and my experience is that these tend to be hard to figure
out by just looking at the code. Typically, I have to undo the refactoring and
then find a way to redo it in smaller steps.

The other situation in which safe, automated refactoring is useful is when
you're dealing with messy legacy code. If you have good test coverage, it's
your safety net that allows you to refactor with confidence, knowing that your tests will tell
you when you veer off course. But sometimes there are no tests and the code is
riddled with dependencies that make it hard to add tests. Doing a safe
refactoring may be what you need to get you started by isolating a part of the
code that can be unit tested.

Current limitations
-------------------

Earlier, I said:

>After trying this out a few times, I can see that my approach so far is
>insufficient for safe refactoring. I have tried to process only the lines that
>are to be extracted. This is a somewhat less sophisticated approach the one
>used in the existing PPIx::EditorTools refactorings. These parse the entire
>Perl file and locate the relevant parts in the parse tree PPI::Document.
>I think I will have to do this too. It's necessary to analyze the scope that
>the selected lines are contained in. I thought I might be able to hack my way
>around that problem, but now I believe it's not worth it.

I'm still working on this. It's finished except for generating the actual code
at the end.

Current design
--------------

The code works as a pipeline, with each class doing one stage of processing.

Analyzer -> VariableSorter -> CodeGenerator

CodeGenerator is not yet implemented, but the idea is that the Analyzer gleans
relevant information from the code about variable use and declarations. Then
the VariableSorter sort the detected variables into "buckets" depending on how
they should be treated in the extracted code. Finally the CodeGenerator
generates the method body and the call to the method.
