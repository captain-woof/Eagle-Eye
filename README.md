# Eagle-Eye

### Table of Contents
  - [Brief introduction](#brief-introduction)
  - [Usage](#usage)
  - [FAQ](#faq)
  - [Author](#author)

### Brief introduction
Eagle-Eye is a simple shell script that can recursively search (any chosen portion of) the filesystem and list out files or folders that contain specific substrings of interest.

**Features:**
  - Search for occurences of files with sensitive content
  - Search the same, but among names of the files/directories
  - Search for any sensitive hashes lying around

### Usage
`./eagle-eye.sh`

### FAQ
- **Q: How do I search only in a single file or group of files only?**
  **A:** Copy the file(s) to a blank directory and use the tool on that directory.

- **Q: The hashes it found are not real. Why?**
  **A:** That's because this script only uses a regex to search for common hashes. If other strings exist that satisfy the regex, those will get shown as well regardless of whether they are actual hashes or not.
- **Q: Why is \<something\> not working?**
  **A:** Please show me the errors so that I can fix it.

### Author

CaptainWoof

Twitter: [@realCaptainWoof](https://www.twitter.com/realCaptainWoof)
