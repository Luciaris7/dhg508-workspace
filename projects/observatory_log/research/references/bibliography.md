# Bibliography · Observatory Log

Markdown only, no reference manager. Every entry records **how it was found**,
**what was actually read**, and **what is still a lead**. A search result is a
lead; only a read passage is a finding.

Search route for everything below: the **OpenAlex works API**
(`https://api.openalex.org/works`), as required by the course
[scholarly-search skill](../../../../.opencode/skills/scholarly-search/SKILL.md).
No Google Scholar automation was used.

---

## Search log

| Date | Query (verbatim) | Route | Outcome |
| --- | --- | --- | --- |
| 2026-11-04 | `search=scientific objectivity atlas observation` | OpenAlex API, 5 results | **Good.** Returned Daston, "On Scientific Observation" (*Isis*, 2008) as the top hit. Also returned irrelevant astronomy papers about comet 3I/ATLAS — the word "atlas" pulls in physical atlases. |
| 2026-11-04 | `search=bureaucratic documents forms knowledge paperwork` | OpenAlex API, 5 results | **Poor for my purpose.** Returned anthropology of migration paperwork and colonial archives (Sağlam 2024; Geoffrion & Cretton 2021; Ning 2022; Siddique 2016; Abrams 2016). None of these is about documents as a *medium* of knowledge, which is the angle I need. Kept as background leads only. |
| 2026-11-04 | `filter=title.search:paper knowledge` | OpenAlex API, 2 results | **Hit.** Gitelman, *Paper Knowledge* (Duke UP, 2014), two records (monograph and edited-book). |
| 2026-11-04 | `filter=title.search:the weird and the eerie` | OpenAlex API, 2 results | **Hit.** Fisher, *The Weird and the Eerie* (Goldsmiths repository record, 2017) plus a review by B. G. Woodard in *Textual Practice*. |
| 2026-11-04 | `works/W1953000548?select=...,abstract_inverted_index,biblio` | OpenAlex API, single record | **Read.** Daston's abstract in full, plus volume/issue/pages. |

Queries I did **not** get to and would try next: `scientific observation trained
judgement`, `forms and formalization media`, `idle game labour repetition`,
`walking simulator landscape`, `cosmic horror indifference nature`.

---

## Works read

### Daston, Lorraine. "On Scientific Observation." *Isis* 99, no. 1 (2008): 97–110. DOI [10.1086/587535](https://doi.org/10.1086/587535). OpenAlex [W1953000548](https://openalex.org/W1953000548).

**Read:** the full abstract (p. 97). **Not read:** the body — the article is
paywalled and I have not obtained it.

**Located material used in the design document:**

- "a turn toward ontology — more specifically, toward ontologies created and
  sustained by observation" (abstract, p. 97).
- The framing of forty years of shared concern with "interaction of subjective and
  objective factors in scientific inquiry" (abstract, p. 97).

**Relevance:** the chart mechanic. Observation as something sustained rather than
received.

**Status:** partially read — sufficient for the abstract claims, **not** sufficient
to attribute any argument to the article's body.

---

## Works identified, not yet read (leads)

### Gitelman, Lisa. *Paper Knowledge: Toward a Media History of Documents*. Durham, NC: Duke University Press, 2014. DOI [10.1215/9780822376767](https://doi.org/10.1215/9780822376767). OpenAlex [W4245455745](https://openalex.org/W4245455745).

**Status: LEAD.** Metadata verified against the OpenAlex record and the DOI.
Full text not read.

**Why it is here:** the report form is the game's central mechanic, and Gitelman is
the obvious scholar for documents as a medium rather than a container.

**What must be checked before the presentation:** the specific claim about forms,
with a chapter and page. Do not quote this work until that is done.

### Fisher, Mark. *The Weird and the Eerie*. London: Repeater, 2016. OpenAlex [W2799136475](https://openalex.org/W2799136475) (Goldsmiths repository record, dated 2017).

**Status: LEAD.** The openalex record dates the deposited manuscript 2017; the
book is generally cited as 2016. **Verify the year against the publisher before
citing.** Full text not read.

**Why it is here:** the northern station as an eerie environment, and the argument
that horror can be structural rather than monstrous.

**What must be checked:** the exact wording of the weird/eerie distinction and its
page. Do not quote this work until that is done.

### Woodard, Benjamin Graham. "The Weird and the Eerie." *Textual Practice* 31 (2017). DOI [10.1080/0950236X.2017.1358704](https://doi.org/10.1080/0950236X.2017.1358704).

**Status: LEAD.** Found while verifying Fisher. This is a **review** of Fisher, not
a fourth position. It may be the cheapest way to get a reliable summary of the
book's argument if the book itself stays out of reach — but a review is a
secondary account and must be presented as such.

---

## Background leads from the failed query (not used)

These came back from the paperwork search and are **not** part of my argument. They
are recorded so the search is honest about what it returned:

- Sağlam, Erol. "Paperwork as statecraft…" *Third World Quarterly* (2024). DOI [10.1080/01436597.2024.2387817](https://doi.org/10.1080/01436597.2024.2387817)
- Geoffrion, Karine, and Viviane Cretton. "Introduction: Bureaucratic Routes to Migration…" *Anthropologica* 63, no. 1 (2021). DOI [10.18357/anthropologica6312021184](https://doi.org/10.18357/anthropologica6312021184)
- Ning, Rundong. "Bureaucratic valves…" *Africa* (2022). DOI [10.1017/S0001972022000328](https://doi.org/10.1017/S0001972022000328)
- Abrams, Thomas. "Disability and Bureaucratic Forms of Life." *Nordic Journal of Science and Technology Studies* 3, no. 1 (2016). DOI [10.5324/njsts.v3i1.2153](https://doi.org/10.5324/njsts.v3i1.2153)

Abrams is the closest of these to my question (forms and lived experience) and is
the one I would read first if I had another day.
