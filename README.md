# sib-swiss-federated-query-extractor

An extractor of federated queries from the [sib-swiss/sparql-examples](https://github.com/sib-swiss/sparql-examples) repository.
The latest extractor run results are [available online](./sib-swiss-federated-queries.json); however, the results are not updated upon changes in [sib-swiss/sparql-examples](https://github.com/sib-swiss/sparql-examples).

## Dependencies
- [Riot](https://jena.apache.org/documentation/io/) or [Raptor](https://librdf.org/raptor/) for the generation of the query dataset of [sib-swiss/sparql-examples](https://github.com/sib-swiss/sparql-examples)
- [Node.js](https://nodejs.org/en)
- [java](https://www.java.com/en/) to use the generator from sib-swiss

## Installation
To extract the queries the [sib-swiss/sparql-examples](https://github.com/sib-swiss/sparql-examples) is added as a submodules,
thus, it is important to make sure that it is [correctly fetched](https://git-scm.com/book/en/v2/Git-Tools-Submodules).
For reproducibility, it is crucial to consider which commit is materialized in the repository.
Commit information is added as metadata in the generated file.

To produce the sib-swiss/sparql-examples first run

```sh
./init.sh
```

and then
```sh
yarn install
```

To install the repository dependencies.

## Generate the federated queries

### Usage

```
Usage: sib-swiss-federated-query-extractor [options]

Options:
  -V, --version                      output the version number
  -i, --ignoreEndpoints <string...>  endpoints to ignore
  -h, --help                         display help for command
```

# How to generate

Run 

```sh
yarn node index.mjs
```

to produce the `./sib-swiss-federated-queries.json`, with this format.

```json
{
  "data": {
    "https://purl.expasy.org/sparql-examples/ontology#neXtProt/NXQ_00091": {
      "query": "PREFIX : <http://nextprot.org/rdf/>\nPREFIX cv: <http://nextprot.org/rdf/terminology/>\n\nselect distinct ?entry where {\n  service <http://drugbank.bio2rdf.org/sparql> {\n    select distinct ?uniprot WHERE {\n\t?drug <http://bio2rdf.org/drugbank_vocabulary:target> ?drugTarget .\n\t?drug <http://bio2rdf.org/drugbank_vocabulary:x-atc> ?atcCode.\n    ?drugTarget <http://bio2rdf.org/drugbank_vocabulary:x-uniprot> ?uniprot .\n\tfilter(!contains(str(?uniprot),\"_\"))\n\tfilter(contains(str(?atcCode), \"atc:C01\" )) # ATC starting with C01 means therapeutic subgroup for cardiac therapy\n    }\n  }\n  BIND (IRI(CONCAT(\"http://nextprot.org/rdf/entry/NX_\",substr(str(?uniprot),28,6))) as ?entry) # cast drugbank id to neXtprot entry\n}",
      "description": "Proteins which are targets of drugs for cardiac therapy",
      "federatesWith": [
        "https://sparql.nextprot.org/sparql",
        "http://drugbank.bio2rdf.org/sparql"
      ],
      "target": "https://sparql.nextprot.org/sparql"
    },...
  },
  "metadata":{
    // UNIX date when this data was generated
    "date": 1730118595470,
    // commit where the data from https://github.com/sib-swiss/sparql-examples was produced
    "commit" : "436f604",
    "number_of_queries": 16,
    "ignored_endpoints": []
  }
}
```

endpoints can be ignored using the `-i` argument.

## One-command update workflow

To update to the latest upstream examples, rebuild `all_queries.ttl`, install JS dependencies, and regenerate
`sib-swiss-federated-queries.json`, run:

```sh
./update-and-extract.sh
```

Exclude endpoint(s) by URL:

```sh
./update-and-extract.sh --ignore-endpoint https://sparql.nextprot.org/sparql
```

or use the shortcut for neXtProt:

```sh
./update-and-extract.sh --ignore-nextprot
```

This will also track the exclusions in the metadata as:

```json
"ignored_endpoints": [
  "https://sparql.nextprot.org/sparql"
]
```

## License
The code is licensed under the MIT license. See the [LICENSE](LICENSE) file for details.
