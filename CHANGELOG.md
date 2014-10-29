
n.n.n / 2014-10-28 
==================

  * Release 0.2.0
  * Merge pull request #4 from rcarver/rc-logfix
  * fix that sql names weren't actually logged
  * Merge pull request #3 from rcarver/rc-batch-query
  * change batch syntax
  * Merge pull request #2 from rcarver/rc-rspec3
  * a note about consistent reads
  * add doc for the :group option and protect from incorrect use
  * add docs for batch
  * specify whether you want the results grouped or not
  * allow passing :batch_size to #query to receive an Enumerator that yields batches
  * provide a fallback when the test database cannot be created nicely
  * illegal to pending without fail
  * stub is double
  * not valid to expect a certain type of exception to be thrown
  * be_true/be_false become be_truthy/be_falsey
  * restore 'its' syntax with gem, and enable deprecated syntax
  * add code climate
  * Release v0.1.4
  * Merge pull request #1 from ceberly/master
  * upsert with :replace and more than one column to update was generating invalid SQL
  * implement _to_partial_path per ActiveModel
  * Release v0.1.3
  * Fix changelog
  * Release v0.1.2
  * relax rake depenency
  * Set load path for ruby 1.9
  * Cucumber now prefers you call other steps via 'step'
  * We'll need to use DELETE instead of TRUNCATE due to an incompatible change in mysql
  * Explicitly join the array to format for the query
  * Setup the test environment better
  * make sure to gsub on a string
  * Fix 'case' syntax for ruby 1.9
  * Release v0.1.1
  * relax from active gems from 3.1.0 to 3.1
  * rails 3.1 compatibility
  * add changelog
0.2.0 / 2014-10-08 
==================

  * fix that sql names weren't actually logged
  * add 'batch' support to #query
  * fix specs to run with rspec 3

0.1.4 / 2012-05-31 
==================

  * upsert with :replace and more than one column to update was generating invalid SQL
  * implement _to_partial_path per ActiveModel

0.1.3 / 2011-12-28 
==================

  * fix botched 0.1.2 release

0.1.2 / 2011-12-28 
==================

  * ruby 1.9 compatibility

0.1.1 / 2011-10-11
==================

  * rails 3.1 compatibility
  
0.1.0 / 2011-09-06
==================

  * Initial released version
