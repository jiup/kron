# Kron

![licence](https://img.shields.io/dub/l/vibe-d.svg) ![gem version](https://img.shields.io/badge/gem-2.1.0-green.svg) ![version](https://img.shields.io/badge/version-0.2.1-green.svg)

Welcome to the **Kron** world! Kron is a distribute version control system which can be used to work both locally and remotely. It is efficient and easy to use, let's now get started by following the steps!

## Installation

Change directory:

    $ cd /path/to/kron/bin/

Execute the setup bash (permission may required):

    $ ./setup

Check usability in your command line:

    $ kron

Congratulation and enjoy!


## Quick Start

For help about a specific command, please use `-h` option before that command

```
$ kron -h command
```

To create a repository, change directory to your target folder and execute

```
$ kron init
```

You’ve now initialized the working directory—you may notice a new directory created, named `./kron` , with  a `.kronignore` file. In order to track the file you are working on, simply use

```
$ kron add file_name
```

To remove files from tracking list, use

```
$ kron remove file_name
```

In order to commit changes, execute the following command with commit message

```
$ kron commit -m 'commit message'
```

A single Kron repository can maintain multiple branches of development. To create a new branch named branch_name, use

```
$ kron branch add branch_name
```

and then, we can type

```
$ kron checkout branch_name
```

to switch to the `branch_name` branch. 

Kron also supports `clone ` and `pull` from remote servers. To open a local port use

```
$ kron serve
```

a local port will be opened with your IP address. When your co-worker is ready,  type

```
$ kron clone serve_address 
```

to clone a remote repository to your current directory. Or you can pull another remote branch to your current one by

```
$ kron pull serve_address branch_name
```

You can merge another branch into your current branch by executing

```
$ kron merge branch_name
```

The change histories already committed can be printed to the screen by

```
$ kron logs
```

or you can print the history of a certain revision of current branch by specifying a revision id

```
$ kron log -c revision_id
```

or specify a the branch name you want to examine.

For detailed kron manual, please type in

```
$ kron help
```

or visit our [design document](https://github.com/jiup/kron/blob/master/DESIGNDOC.md) to see all available commands of your Kron.



## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake test` to run the tests. You can also run `bin/kron` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).



## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/jiup/kron. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [Contributor Covenant](http://contributor-covenant.org) code of conduct.



## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).



## Code of Conduct

Everyone interacting in the Kron project’s codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/jiup/kron/blob/master/CODE_OF_CONDUCT.md).
