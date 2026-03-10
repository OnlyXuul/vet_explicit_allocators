package vet_explicit_allocators

import "core:os"
import "core:fmt"
import "core:strings"
import "core:bytes"

to_bytes :: proc(s: string) -> []byte { return transmute([]byte)(s) }

read_and_recurse_dir :: proc(rootpath: string, paths: ^[dynamic]string, allocator := context.allocator, loc := #caller_location) {
	fi, err := os.read_all_directory_by_path(rootpath, context.allocator)
	defer os.file_info_slice_delete(fi, context.allocator)
	for f in fi {
		if os.is_file(f.fullpath) && os.ext(f.fullpath) == ".odin" {
			append(paths, strings.clone(f.fullpath, allocator, loc), loc)
		} else if os.is_dir(f.fullpath) {
			read_and_recurse_dir(f.fullpath, paths, allocator, loc)
		}
	}
}

update_files :: proc(paths: []string, opt: enum { add, remove }) {
	//	loop on each file in list
	loop: for path in paths {
		data, data_err := os.read_entire_file_from_path(path, context.allocator)
		defer delete(data, context.allocator)

		//	only search lines up until index of "package"
		package_idx := bytes.index(data, to_bytes("package"))
		lines := bytes.split(data[:package_idx], {'\n'}, context.allocator)
		defer delete(lines, context.allocator)

		//	search lines for instance of "#+vet explicit-allocators"
		//	idx == 0 means it was found to be at the beginning of a line (i.e. not commented out)
		vet := to_bytes("#+vet explicit-allocators\n")
		for line in lines {
			//	newline was used to split lines, so must check for bytes without newline
			//	we only care if the line begins with our target anyway
			if idx := bytes.index(line, to_bytes("#+vet explicit-allocators")); idx == 0 {
				//	if found and flagged to remove
				if opt == .remove {
					//	only remove n times, to prevent parsing entire file
					n := bytes.count(data, vet)
					newdata, removed := bytes.remove(data, vet, n, context.allocator)
					if removed {
						defer delete(newdata, context.allocator)
						assert(len(newdata) == len(data) - (len(vet) * n))
						write_err := os.write_entire_file_from_bytes(path, newdata[:])
						if write_err != nil {
							fmt.eprintln(os.error_string(write_err))
						} else {
							fmt.println("Updated:", path)
						}
					}
				}
				continue loop // continue loop if found: stop checking lines, skip add below, and check next path
			}
		}
		//	if not found and flagged to add
		if opt == .add {
			newdata, newdata_err := bytes.concatenate_safe({vet, data}, context.allocator)
			defer delete(newdata, context.allocator)
			if len(data) != 0 && data_err == nil && newdata_err == nil {
				assert(len(newdata) == len(data) + len(vet))
				write_err := os.write_entire_file_from_bytes(path, newdata[:])
				if write_err != nil {
					fmt.eprintln(os.error_string(write_err))
				} else {
					fmt.println("Updated:", path)
				}
			}
		}
	}
}

main :: proc () {
	if len(os.args) == 3 && (os.args[2] == "-a" || os.args[2] == "-r") {
		if os.is_dir(os.args[1]) {
			paths := make([dynamic]string, context.allocator)
			defer delete(paths)
			defer {for p in paths { delete(p, context.allocator) }}
			read_and_recurse_dir(os.args[1], &paths, context.allocator)
			switch os.args[2] {
			case "-a": update_files(paths[:], .add)
			case "-r": update_files(paths[:], .remove)
			}
		} else if os.is_file(os.args[1]) {
			switch os.args[2] {
			case "-a": update_files({os.args[1]}, .add)
			case "-r": update_files({os.args[1]}, .remove)
			}
		}
	} else {
		fmt.printfln("%-8s%s%s", "Usage:", "vet_explicit_allocators <file or directory>", "[-a | -r]")
		fmt.printfln("%-8s%s", "", "Only 1 flag at a time allowed\n")
		fmt.printfln("%-8s%s", "-a", "add '#+vet explicit-allocators' to all .odin file(s) recursively if not found.")
		fmt.printfln("%-8s%s", "-r", "remove '#+vet explicit-allocators' from all .odin file(s) recursively if found.")
	}
}