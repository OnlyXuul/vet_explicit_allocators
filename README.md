# vet_explicit_allocators
Simple program to add or remove #+vet explicit-allocators build option to a single .odin file, or all .odin files in a directory.<br>
<br>
**Backup files before testing**

```bash
cd folder_for_projects
git clone https://github.com/OnlyXuul/vet_explicit_allocators.git
cd vet_explicit_allocators
odin build .
```
## Usage
- For usage output, just run program without any arguments.
- For best experience, copy the compiled program to a folder in your PATH so that it can be run from anywhere.
- This should be OS agnostic, but I am only able to test on Linux at the moment. Make sure to backup files before testing in your environment.

## General use examples:
### Add to all files recursively in current directory. To remove, do the same but with -r.
```bash
vet_explicit_allocators . -a
```
### Add to all files in sub directory. To remove, do the same but with -r.
```bash
vet_explicit_allocators subdir -a
```
### Add to all files recursively in specific directory. To remove, do the same but with -r.
```bash
vet_explicit_allocators path_to_folder -a
```
### Add to single file current directory. To remove, do the same but with -r.
```bash
vet_explicit_allocators myfile.odin -a
```
### Combining this with odin check
```bash
cd project_folder
vet_explicit_allocators . -a && odin check .
```
### Combining this with odin check and then remove after
```bash
cd project_folder
vet_explicit_allocators . -a && odin check . && vet_explicit_allocators . -r
```
