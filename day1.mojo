
@value
struct Digit(CollectionElement):
    var spelled_out: String
    var digit: String

    alias one = Digit("one", "1")
    alias two = Digit("two", "2")
    alias three = Digit("three", "3")
    alias four = Digit("four", "4")
    alias five = Digit("five", "5")
    alias six = Digit("six", "6")
    alias seven = Digit("seven", "7")
    alias eight = Digit("eight", "8")
    alias nine = Digit("nine", "9")


    def is_substr(self: Self, to_check: String) -> Bool:
        for i in range(len(to_check)):
            if to_check[i] != self.spelled_out[i]:
                return False

        return True

    def is_backstr(self: Self, to_check: String) -> Bool:
        for i in range(1, len(to_check) + 1):
            if to_check[len(to_check) - i] != self.spelled_out[len(self.spelled_out) - i]:
                return False

        return True


def extract_calibration_pt1(token: String) -> Int:
    var buffer = String()
    var idx: Int = 0
    while idx < token.__len__():
        let c: String = token.__getitem__(idx)
        if isdigit(c._buffer[0]):
            buffer += c

        idx += 1

    return atol(buffer[0] + buffer[len(buffer) - 1])

def is_numeric_digit(s: String, digits: DynamicVector[Digit]) -> Int:

    for i in range(len(digits)):
        let digit: Digit = digits[i]
        if s == digit.spelled_out:
            return i

    return -1

def isdigit_backstr(to_check: String) -> Bool:
    if Digit.one.is_backstr(to_check) or 
        Digit.two.is_backstr(to_check) or 
        Digit.three.is_backstr(to_check) or 
        Digit.four.is_backstr(to_check) or 
        Digit.five.is_backstr(to_check) or 
        Digit.six.is_backstr(to_check) or 
        Digit.seven.is_backstr(to_check) or 
        Digit.eight.is_backstr(to_check) or 
        Digit.nine.is_backstr(to_check):
        return True

    return False

def isdigit_substr(to_check: String) -> Bool:
    if Digit.one.is_substr(to_check) or 
        Digit.two.is_substr(to_check) or 
        Digit.three.is_substr(to_check) or 
        Digit.four.is_substr(to_check) or 
        Digit.five.is_substr(to_check) or 
        Digit.six.is_substr(to_check) or 
        Digit.seven.is_substr(to_check) or 
        Digit.eight.is_substr(to_check) or 
        Digit.nine.is_substr(to_check):
        return True

    return False

def parse_next_token(pos: Int, token: String, digits: DynamicVector[Digit], direction: Int) -> String:
    # Read left to right into a buffer. Clear if:
    # - The latest char is a digit
    # - The buffer so far _can't_ be a digit (spelled out)
    # - The buffer so far _is_ a (spelled out) digit

    var buffer = String()
    var idx = pos
    while True:
        if direction == 1:
            buffer += token[idx]
        else:
            buffer = token[idx] + buffer

        # First exit: is the current char
        if isdigit(token._buffer[idx]):
            return token[idx]

        # Next exit: check if buffer so far is a digit
        let is_digit_idx = is_numeric_digit(buffer, digits)
        if is_digit_idx >= 0:
            return digits[is_digit_idx].digit

        # Next exit: check if the buffer so far CAN'T be a digit
        # In this case, drop letters (from the front or back depending on direction) until it could be again
        if direction == 1:
            while ~(isdigit_substr(buffer) or buffer == ""):
                let tmp = String(buffer)
                buffer = ""
                for i in range(1, len(tmp)):
                    buffer += tmp[i]
        else:
            while ~(isdigit_backstr(buffer) or buffer == ""):
                buffer._buffer.pop_back()
        
        # Advance ptr
        idx += direction


def extract_calibration_pt2(line: String) -> Int:
    let digits = __get_digits()

    first = parse_next_token(0, line, digits, 1)
    last = parse_next_token(len(line)-1, line, digits, -1)

    return atol(first + last)


def solution():
    var total: Int = 0

    with open("day1.input", 'r') as f:
        let lines: DynamicVector[String] = f.read().split("\n")
        lines.size

        var idx = 0
        while idx < lines.size:
            total += extract_calibration_pt2(lines[idx])
            idx += 1

    print(total)


def __get_digits() -> DynamicVector[Digit]:
    var digits = DynamicVector[Digit]()

    digits.append(Digit.one)
    digits.append(Digit.two)
    digits.append(Digit.three)
    digits.append(Digit.four)
    digits.append(Digit.five)
    digits.append(Digit.six)
    digits.append(Digit.seven)
    digits.append(Digit.eight)
    digits.append(Digit.nine)

    return digits

def part2_test():
    var lines = DynamicVector[String]()
    lines.append("two1nine")
    lines.append("eightwothree")
    lines.append("abcone2threexyz")
    lines.append("xtwone3four")
    lines.append("4nineeightseven2")
    lines.append("zoneight234")
    lines.append("7pqrstsixteen")

    var total = 0
    for i in range(len(lines)):
        c = extract_calibration_pt2(lines[i])
        total += c

    if total != 281:
        raise Error("Expected " + str(281) + " but got " + total)

def test_case(test_str: String, result: Int):
    if extract_calibration_pt2(test_str) != result:
        raise Error("Expected " + str(result) + " but got " + extract_calibration_pt2(test_str))

def main():
    test_case("tzxrgthree8sixtzszjscq", 36)
    test_case("spone1ninendxnqxfqvh", 19)
    part2_test()

    solution()