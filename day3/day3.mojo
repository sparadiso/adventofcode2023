@value
struct Point(Stringable, CollectionElement):
    var row: Int
    var col: Int

    fn __eq__(self: Self, other: Point) -> Bool:
        return self.row == other.row and self.col == other.col

    fn __str__(self: Self) -> String:
        return str(self.row) + ", " + str(self.col)

    fn __add__(self: Self, other: Point) -> Point:
        return Point(self.row+other.row, self.col+other.col)

@value
struct Board:
    var n_rows: Int
    var n_cols: Int
    var data: DynamicVector[String]

    def is_valid(self: Self, pt: Point) -> Bool:
        return pt.col >= 0 and pt.col < self.n_cols and pt.row >= 0 and pt.row < self.n_rows

    def index(self: Self, pt: Point) -> Int:
        return pt.row * self.n_cols + pt.col

    def point(self: Self, idx: Int) -> Point:
        let row: Int = (idx / self.n_cols).to_int()
        let col: Int = idx % self.n_cols

        return Point(row, col)

    def get(self: Self, index: Int) -> String:
        return self.data[index]

    def get(self: Self, row: Int, col: Int)->String:
        return self.data[self.index(Point(row, col))]

    def get(self: Self, pt: Point)->String:
        return self.data[self.index(pt)]

    fn __init__(inout self: Self, fname: String) raises:
        self.data = DynamicVector[String]()

        var lines = DynamicVector[String]()
        var data = String() 

        with open(fname, 'r') as f:
            data = f.read()

        lines = data.split("\n")

        self.n_rows = len(lines)
        self.n_cols = len(lines[0])

        for i in range(self.n_rows):
            for j in range(self.n_cols):
                self.data.append(lines[i][j])

def advance_to_next_number(borrowed board: Board, start_pos: Int) -> Int:
    # Start at a point, keep stepping until you hit a number
    # Return -1 if you hit the end of the board
    var pos = start_pos
    while ~isdigit(board.get(pos)._buffer[0]):
        pos += 1

        if pos >= len(board.data):
            return -1
    
    return pos

def parse_number_at_pos(borrowed board: Board, pos: Int) -> Int:
    # Assume pos is the start of a number. Just read forward until the end and return it.
    var pt = board.point(pos)
    var buffer = String()
    while pt.col < board.n_cols:
        if ~isdigit(board.get(pt)._buffer[0]):
            return atol(buffer)
        else:
            buffer += board.get(pt)

        pt.col += 1

    return atol(buffer)

def check_boundary_for_symbol(borrowed board: Board, start_pt: Point, width: Int, is_symbol: fn(x: String)->Bool) -> Bool:
    # Find the border elements
    # Check start point
    var cur_pos = start_pt

    while cur_pos.col < start_pt.col + width:
        # Check the square
        for dr in VariadicList(-1, 0, 1):
            for dc in VariadicList(-1, 0, 1):
                let test_pt = board.point(board.index(cur_pos + Point(dr, dc)))
                if board.is_valid(test_pt):
                    if is_symbol(board.get(test_pt)):
                        return True

        cur_pos.col += 1

    return False

fn __is_symbol(char: String) -> Bool:
    return ~(char == ".") and ~isdigit(char._buffer[0])
    
def __print_neighborhood(board: Board, x0: Point, width: Int):
    print("Printing neighborhood of", x0, width)
    let r0 = x0.row - 1
    var r = r0

    while r <= x0.row + 1:
        c = x0.col - width 
        while c <= x0.col + width:
            # print(Point(r, c), board.is_valid(Point(r, c)))

            if board.is_valid(Point(r, c)):
                print_no_newline(board.get(Point(r, c)))
            c += 1
        r += 1
        print()
    print()

def part1(fname: String):
    let board = Board(fname)

    var pos = advance_to_next_number(board, 0)
    var total = 0
    while pos >= 0:
        print(pos, "of", len(board.data), board.point(pos))
        let n = parse_number_at_pos(board, pos)

        let start_pt = board.point(pos)
        let end_pt = board.point(pos + len(str(n)))
        let touching = check_boundary_for_symbol(board, start_pt, len(str(n)), __is_symbol)

        # __print_neighborhood(board, start_pt, len(str(n)))
        # print("Touching = ", touching)

        if touching:
            total += n

        pos = advance_to_next_number(board, pos + len(str(n)))
    
    print(total)

def find_gears(board: Board) -> DynamicVector[Point]:
    var result = DynamicVector[Point]()

    for i in range(len(board.data)):
        if board.get(i) == "*":
            result.append(board.point(i))

    return result

def find_digits(borrowed board: Board, gear: Point) -> DynamicVector[Point]:
    # Look around the gear, identify all the digits. 
    var digits = DynamicVector[Point]()

    for row in VariadicList(-1, 0, 1):
        for col in VariadicList(-1, 0, 1):
            let test_point = gear + Point(row, col)
            if board.is_valid(test_point):
                if isdigit(board.get(test_point)._buffer[0]):
                    digits.append(test_point)

    var unique_starts = DynamicVector[Point]()
    let left = Point(0, -1)

    # Burn left to the start of the number
    for i in range(len(digits)):
        var cursor = Point(digits[i].row, digits[i].col)
        var test_pt = cursor + left
        while board.is_valid(test_pt) and isdigit(board.get(test_pt)._buffer[0]):
            cursor = test_pt
            test_pt = cursor + left

        # (Dedup)
        # The cursor is now at the left most digit
        # If this point does not exist in the set, add it
        var match_found = False
        for j in range(len(unique_starts)):
            if cursor == unique_starts[j]:
                match_found = True

        if ~match_found:
            unique_starts.append(cursor)

    return unique_starts

def read_digits(board: Board, locs: DynamicVector[Point]) -> DynamicVector[Int]:
    var digits = DynamicVector[Int]()

    for i in range(len(locs)):
        digits.append(parse_number_at_pos(board, board.index(locs[i])))

    return digits

def part2(fname: String): 
    let board = Board(fname)

    let gears: DynamicVector[Point] = find_gears(board)
    
    var total = 0

    for i in range(len(gears)):
        # __print_neighborhood(board, gears[i], 5)
        let digit_locs: DynamicVector[Point] = find_digits(board, gears[i])
        let digits: DynamicVector[Int] = read_digits(board, digit_locs)

        if len(digits) == 2:
            total += digits[0] * digits[1]

    print(total)

def main():
    part2("day3.input")
