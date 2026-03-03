# JobHuntingEx

A website to help get better job listings, and help automate some of the job hunting process.
Currently only supports job listings from dice.

# Site Images
![home](/docs/home.png)
![search](/docs/search.png)

# Query Architecture
![query](/docs/Untitled-2026-02-28-0929.png)

## Why use an LLM?
LLMs are useful to extract information that might not be listed in the job description such as minimum years of experience required for the job.
Currently, it costs about $0.01 to process 100 job listings. Although, it's still not 100% accurate, the information retrieved is usually close enough. Given that it would be impossible to apply to every job anyways I think the user would be okay to miss out on a couple of listings because they might have gotten mislabeled.

