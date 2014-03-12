perl-extract-method
===================

A serious attempt to get serious refactoring tool support for Perl code.

How to try it
-------------

NOTE: This hasn't been tested for a while. It might not work as advertised.

1. Install PPIx::EditorTools and App::EditorTools from CPAN.
2. Install the Vim script as explained in [the documentation](https://metacpan.org/module/App::EditorTools::Vim).
2. Clone this repository.
3. Add the lib directory to your Perl include path.
4. Copy `share/extract_method.vim` to `ftplugin/perl` in your vim directory.
5. To use it in Vim, select the code you want to extract, and do :call ExtractMethod(). Add a keyboard mapping if you want.

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

Current design
--------------

The code works as a pipeline, with each class doing one stage of processing.

Analyzer -> VariableSorter -> CodeGenerator -> CodeEditor

The **Analyzer** gleans relevant information from the code about variable use and declarations.

The **VariableSorter** sorts the detected variables into "buckets" depending on how
they should be treated in the extracted code.

The **CodeGenerator** generates the method body and the call to the method.

The **CodeEditor** handles inserting the generated code at the correct
locations in the file that's being edited.

The main **ExtractMethod** class handles the overall process, delegating the
steps to the others.

Analyzing the variables
-----------------------

The most difficult part of this refactoring is analyzing the variables.

The code example illustrates the distinctions on which the analysis is based.
The code inside the red rectangle is the code selected for extraction. We need
to know which variables cross the boundaries of the selected code segment. Any
variable that exists only inside or only outside the selected region can be
ignored for the purposes of the refactoring. The categories that need to be
identified are represented by the three arrows:

**Variables that are declared before and used inside the selected code:** (upper short
arrow). These variables are passed to the extracted method.

**Variables that are declared inside and used after the selected code:** (lower short
arrow). These variables are returned from the extracted method. However,
this is only necessary if the later use is inside the scope that contains the
selected code.

**Variables that are declared before, used inside and after the selected code:** (long
arrow). These variables are passed to and returned from the extracted method.
Actually, this only necessary if the variables are *assigned to* in the
selected code, but the current implmentation does not check this.

![Code example](https://www.evernote.com/shard/s212/sh/3653d26e-4a58-4e8a-ade1-a0a351d12fa2/4424fe85ebc6a8b672d4e3915b611ff6/deep/0/Screenshot%2027.05.13%2012:04.png)
Current limitations
-------------------

I'm sure there are many more limitations than these. These are just some that occurred to
me or that I've come across while testing.

* No Emacs support.
* Does not handle `$#foo`
* Does not give you any warning if the code you select includes part of
  a scope, rendering the refactoring meaningless.
* `$self` is hard-coded as the variable representing the current instance.
* Ignores some [special variables](http://perldoc.perl.org/perlvar.html#SPECIAL-VARIABLES), 
  but not all. Relatively simple to fix by adding to the `is_special_variable` method of the
  Variable class.
* Does not handle or warn about `return` statements inside the selected code.
* Often returns variables unnecessarily from the extracted method. If
  a variable is defined before the extracted region and used after it, the
  extracted method always returns the variable. This is only necessary if the
  variable has been assigned to inside the extracted method (or if it's a hash
  or array that's not a reference and its contents have been changed), and that
  probably does not happen often. UPDATE: this is now fixed in the case of
  scalars.
* Possible collisions with variable names when referencing and dereferencing
  arrays and hashes. I chose not to create cryptic names for the references.
  It's more readable, but unsafe.
* Errors and warnings from the `editortools` code end up inside the document
  instead of of being displayed in a user-friendly manner. 
* The principle of looking after the selected code for variables to return
  will not always work if the selected region code is inside a loop;

The following two are only cosmetic; they have no effect on how the code
works.

* When there are no variables to return, the extracted method uselessly returns
  an empty array: `return ();`
* The resulting code is not indented nicely. You have to do that manually
  afterwards.



