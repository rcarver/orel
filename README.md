# Orel

An object-relational bridge. It focuses on the relational side more than others
without sacrificing on the object side.

## Goals

The overall goal of Orel is to provide a better DSL for doing relational
design. Specifically:

* The basic structure and syntax emphasizes keys. Emphasis on a "primary
  key" is reduced.
* Attributes are NOT NULL by default.
* There is no strict table/class relationship. This reduces the overhead
  and object complexity of using higher forms of normalization.
* Domains (types) are a core part of the model. Though implemented in
  Ruby, Orel domains act more like attribute constraints.



