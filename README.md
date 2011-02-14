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

Orel works on top of ActiveRecord and Arel. It borrows some ideas from
DataMapper, such as schema generation.

## Status

Orel is experimnental and not at all ready to use. See the [cucumber stories](./features)
for up a look at what's supported.

## Author

Ryan Carver (@rcarver / ryan@typekit.com)

## License

MIT

