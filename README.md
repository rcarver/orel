# Orel

An object-relational mapper. It focuses on the relational model more than others.

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

## Integration

Orel is built on top of Arel, which uses ActiveRecord.

## Status

Orel is experimnental and not at all ready to use. See the [cucumber stories](./features)
for up a look at what's supported.

## Inspiration

Reading [Database in Depth][did] reminded me how little ActiveRecord
does to help you build a traditional relational model. DataMapper does better -
basic concepts such as composite keys are possible. Even still, the
basic syntax does not encourage good design.

## Author

Ryan Carver (@rcarver / ryan@typekit.com)

## License

MIT


[did]: http://www.amazon.com/Database-Depth-Relational-Theory-Practitioners/dp/0596100124
