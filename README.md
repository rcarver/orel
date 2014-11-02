# Orel

[![Build Status](https://travis-ci.org/rcarver/orel.svg?branch=master)](https://travis-ci.org/rcarver/orel)
[![Code Climate](https://codeclimate.com/badge.png)](https://codeclimate.com/github/rcarver/orel)

An object-relational mapper. It focuses on the relational model more
than others.

## Goals

The overall goal of Orel is to provide a better DSL for doing relational
design. Specifically:

* The basic structure and syntax emphasizes keys. Emphasis on a "primary
  key" is reduced.
* Attributes are always NOT NULL.
* There is no strict table/class relationship. This reduces the overhead
  and object complexity of using higher forms of normalization.
* Domains (types) are a core part of the model. Though implemented in
  Ruby, Orel domains act more like attribute constraints.

## Integration

Orel is built on top of Arel, which uses ActiveRecord connection
adapters. It is compatible with ActiveModel::Naming and borrows support
for other basic functionality from ActiveModel.

## Status

Orel has been used in a production environment for several years.
However, the Object interface is lightly used. You may find the APIs
lacking if you are using the Object interface. See the [cucumber
stories](./features) for up a look at what's supported.

## Features

Following is a summary of the high level features of Orel.

#### Class-based heading definition.

Relations are defined by their heading, and done so within Ruby classes.

    class User
      heading do
        key { first_name / last_name }
        att :first_name, Orel::Domains::String
        att :last_name, Orel::Domains::String
      end
    end

This created a relation called `users` with two string attributes and a
composite key of those attributes.

Classes may define more than one heading.

    class User
      heading do
        key { first_name / last_name }
        att :first_name, Orel::Domains::String
        att :last_name, Orel::Domains::String
      end
      heading :logins do
        key { User }
        att :ip_address, Orel::Domains::String
      end
    end

Which introduces us to **references** and **simple associations**. We've
defined a relation called `user_logins` with one string attribute. Orel
defines two other attributes for us - `first_name` and `last_name` and
creates a foreign key relationship between `users` and `user_logins`. We
have set the key of `user_logins` as all of the attributes used by the
reference to `User` (`first_name`, `last_name`). Put simply, we have
written "a user has many logins" by describing the schema and foreign
key relationships.

Standard associations are easy to talk about now.

    class User
      heading do
        key { first_name / last_name }
        att :first_name, Orel::Domains::String
        att :last_name, Orel::Domains::String
      end
    end
    class Thing
      heading do
        key { User / name }
        att :name, Orel::Domains::String
        ref User
      end
    end

Now we have two separate classes with their own heading. Since Thing
references User, we've defined "thing belongs to user" as well as "user
has many things". The key on Thing says that a User may only have one
thing of any particular name.

#### Domains (types)

Write about domains later.

#### Objects

Now that we've defined some relations, we can use Orel to create,
update, delete objects that represent data within them. We can also
access the foreign key references as associations among those objects.

For the following examples, assume the following classes.

    class User
      heading do
        key { first_name / last_name }
        att :first_name, Orel::Domains::String
        att :last_name, Orel::Domains::String
      end
      heading :logins do
        key { User / ip_address }
        att :ip_address, Orel::Domains::String
      end
    end
    class Thing
      heading do
        key { User / name }
        att :name, Orel::Domains::String
        ref User
      end
    end

The basic CRUD operations on an Orel object resemble ActiveRecord. In
fact, Orel objects are ActiveModel compatible.

    user = User.new :first_name => "John", :last_name => "Smith"
    user.valid?
    # => true
    user.save

Or more succinctly,

    user = User.create :first_name => "John", :last_name => "Smith"

Now that we have a user, give him a thing.

    thing = Thing.create User => user, :name => "Box"

Associations are described via their class. Similarly, we can ask for
information from the user and thing.

    user.first_name
    # => "John"
    thing.name
    # => "Box"
    user[Thing][0].name
    # => "Box"
    thing[User].first_name
    # => "John"

Simple associations are similar. To create a record in the `user_logins`
relation, we can append add it, then save the user.

    user[:logins] << { :ip_address => "192.0.0.1" }
    user.save

Simple associations can define one-to-one relationships as well. For
example.

    class User
      heading do
        key { name }
      end
      heading :account_status do
        key { User }
        att :value, Orel::Domains::String
      end
    end

    user[:account_status] = { :value => "ok" }
    user.save

Here the attributes passed are merged with the current values. Behind
the scenes, Orel intelligently adds and updates only the modified
records.

As you may have guessed, simple associations are pretty limited but
provide a convenient way to model behavior-less one-to-one and
one-to-many relationships without the overhead of defining whole
classes. As well, they are the only place that Orel cascades the `save`
operation to children.

#### Retreiving data

Orel provides two type of query interfaces. One lets you interact
directly with tables, the other lets you interact with objects. Both
defer to Arel to construct the underlying SQL query, and ActiveRecord to
execute and return the raw data.

#### Working with tables

`Orel::Table` provides a simple interface for CRUD operations.
Operations can be run directly against the table heading without any
objects.

Here are some examples of retrieving data. Records are returned as Hash
with Symbol keys.

    # Get all records in the table.
    User.table.row_list

    # Get the number of records in the table.
    User.table.row_count

    # Perform an Arel query against the table.
    User.table.query do |q, table|
      q.project table[:first_name]
      q.where table[:first_name].gte("c")
    end

    # Access the table of a simple association.
    User.table(:ip_address).row_list

Here are some examples of inserting and updating data in the table.

    # Insert a new record.
    User.table.insert(:first_name => "John" ...)

    # Batch update records.
    User.table.update(
      :find => { :first_name => "John" },
      :set  => { :last_name => "Doe" }
    )

    # Upsert (insert or append new data)
    User.table.upsert(
      :insert { :first_name => "John" ... },
      :update { :values => [:age], :with => :increment }
    )

    # Delete records.
    User.table.delete(:first_name => "John")

#### Retrieving objects

Orel provides simple finders, and a powerful query interface. The
result of all object finders are full objects.

    # Find record by its "primary" key.
    User.find_by_primary_key(:first_name => "John", :last_name => "Doe")

    # Find a record by another key.
    User.find_by_key(:other, :attr => "value")

    # Find all records matching a simple condition.
    User.find_all(:first_name => "John")

Much more powerful queries, including joins, can be performed using the
`Orel::Query` interface.

    # Query users across multiple headings.
    User.query do |q, user|
      # Specify a condition on the user table.
      q.where user[:first_name].eq('John')
      # Specify a condition on a join table.
      q.where user[:logins][:ip].eq('127.0.0.1')
      # Return objects with `logins` data also populated.
      q.project user[:logins]
    end

#### Query in batches.

In both the Table and Object `query` methods it's possible to iterate
through a large table by querying for batches of records at a time. This
is done by specifying the "size" of the batch to return. The result of a
batch query is an `Enumerator` object. You can treat this object like
any `Enumerable` and call `each` on it to efficiently move through very
large data sets.

Batch queries are performed using `LIMIT, OFFSET` in MySQL. You should
be aware of the characteristics of these types of queries before using.
For example, read about [nonblocking read](http://dev.mysql.com/doc/refman/5.0/en/innodb-consistent-read.html).

    # Query 1000 users at a time
    User.query do |q, user|
      q.query_batches :size => 1000
    end

    # Query 1000 records at a time
    User.table.query do |q, user|
      q.project user[:first_name]
      q.query_batches :size => 1000
    end

## Inspiration

Reading [Database in Depth][did] reminded me how little ActiveRecord
does to help you build a traditional relational model. DataMapper does
better - basic concepts such as composite keys are possible. Even still,
the basic syntax does not encourage good design.

## Author

Ryan Carver (@rcarver / ryan@typekit.com)

## License

Copyright © 2011-2014 Ryan Carver. Licensed under Ruby/MIT, see LICENSE.

[did]: http://www.amazon.com/Database-Depth-Relational-Theory-Practitioners/dp/0596100124

