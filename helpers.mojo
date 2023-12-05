fn join(delimiter: String, list: DynamicVector[Int]) -> String:
    var buffer = String()
    for i in range(len(list)-1):
        buffer += str(list[i]) + delimiter
    buffer += str(list[len(list)-1])
    return buffer


fn max(list: DynamicVector[Int]) -> Int:
    var max_val = list[0] 
    for i in range(1, len(list)):
        if max_val < list[i]:
            max_val = list[i]

    return max_val

fn min(list: DynamicVector[Int]) -> Int:
    var min_val = list[0] 
    for i in range(1, len(list)):
        if min_val > list[i]:
            min_val = list[i]

    return min_val
