def analyze_bw_stat():
    interested = []
    with open("res_out/rnic_sys_test.txt", "r") as f:
        for line in f.readlines():
            if "con_time" in line:
                interested.append(line)
    with open("res_out/temp_result.txt", "w") as f:
        for line in interested:
            f.writelines(line)
    
def main():
    analyze_bw_stat()

if __name__ == "__main__":
    main()
