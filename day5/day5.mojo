def max(a: Int, b: Int) -> Int:
    if a > b:
        return a
    return b

def min(a: Int, b: Int) -> Int:
    if a < b:
        return a
    return b

@value
struct Set(CollectionElement, Stringable):
    var elements: DynamicVector[Interval]

    def drop_empty(inout self: Self):
        var new_elements = DynamicVector[Interval]()

        for i in range(len(self.elements)):
            if self.elements[i] != Interval.empty and self.elements[i].right >= self.elements[i].left:
                new_elements.append(self.elements[i])

        self.elements = new_elements^

    fn __sub__(self: Self, other: Set) -> Set:
        var tmp = Set(self.elements)
        for i in range(len(other.elements)):
            tmp.remove(other.elements[i])
        return tmp

    fn __eq__(self: Self, other: Set) -> Bool:
        # Two sets are equal if a - b and b - a are both empty
        var tmp = self - other
        for i in range(len(tmp.elements)):
            if ~(tmp.elements[i] == Interval.empty):
                return False

        tmp = other - self
        for i in range(len(tmp.elements)):
            if ~(tmp.elements[i] == Interval.empty):
                return False
        
        return True

    fn __str__(self: Self) -> String:
        if len(self.elements) == 0:
            return "{ empty }"

        var buffer = String("{")

        for i in range(len(self.elements)-1):
            buffer += str(self.elements[i]) + ", "

        buffer += str(self.elements[len(self.elements)-1]) + "}"
    
        return buffer

    fn __init__(inout self: Self, lst: VariadicList[Tuple[Int, Int]]):
        self.elements = DynamicVector[Interval]()
        for i in range(len(lst)):
            self.elements.append(Interval(lst[i].get[0, Int](), lst[i].get[1, Int]()))

    fn __init__(inout self: Self, interval: Interval):
        self.elements = DynamicVector[Interval]()
        self.elements.append(interval)


    fn remove(inout self: Self, to_remove: Interval):
        # To remove an interval from a set, iterate over the set's intervals
        # If the existing interval contains the interval to remove
        # shorten it (potentially to the empty set)
        for i in range(len(self.elements)):
            let e = self.elements[i]
            # {(1, 5), (7, 9)} n (3, 7) => {(1, 3), (8, 9)}

            # Skip elements unless they overlap
            if self.elements[i].overlaps(to_remove):
                # The interval overlaps - could be from the left, in the middle or over the right
                # left or right just mutate the interval
                # from the middle requires creating a new interval
                
                # check middle
                if e == to_remove:
                    self.elements[i] = Interval.empty

                elif e.left <= to_remove.left and e.right >= to_remove.right:
                    # split
                    self.elements[i].right = to_remove.left - 1
                    self.elements.append(Interval(to_remove.right + 1, e.right))

                elif e.left >= to_remove.left and e.right >= to_remove.right:
                    # check left
                    # (1, 5) - (1, 3) => (3, 5)
                    # but if (1, 5) - (1, 8) then just drop it entirely
                    self.elements[i].left = to_remove.right + 1
                elif e.right >= to_remove.left and e.right <= to_remove.right:
                    self.elements[i].right = to_remove.left - 1

                # When all is said and done, check to see if we ate this whole interval
                if self.elements[i].left > self.elements[i].right:
                    self.elements[i] = Interval.empty


@value
@register_passable
struct Interval(CollectionElement, Stringable, Sized):
    var left: Int
    var right: Int

    alias empty = Interval(-1,-1)

    fn __len__(self: Self) -> Int:
        if self == Interval.empty:
            return 0

        return self.right - self.left + 1

    fn __str__(self: Self) -> String:
        return String() + "[" + self.left + ", " + self.right + "]"

    fn __ne__(self: Self, other: Interval) -> Bool:
        return ~self.__eq__(other)

    fn __eq__(self: Self, other: Interval) -> Bool:
        return self.left == other.left and self.right == other.right

    fn overlaps(self: Self, other: Interval) -> Bool:
        # (1, 5) n (5, 6)
        return ~(self == Interval.empty) and 
               ~(other == Interval.empty) and 
               (self.right >= other.left and self.left <= other.right)

@value 
struct EntityRange(CollectionElement, Stringable):
    var entity_type: String
    var ids: Set 

    fn __str__(self: Self) -> String:
        return self.entity_type + ": " + str(self.ids)

@value 
struct Entity(Stringable):
    var entity_type: String
    var id: Int

    fn __str__(self: Self) -> String:
        return self.entity_type + ": " + self.id

@value
struct Range(CollectionElement, Stringable):
    var source: Int
    var destination: Int
    var range: Int

    def contains(self: Self, id: Int) -> Bool:
        return id >= self.source and id < (self.source + self.range)

    fn __init__(inout self: Self, line_to_parse: String) raises:
        # destination source range
        let values = line_to_parse.split(" ")
        self.destination = atol(values[0])
        self.source = atol(values[1])
        self.range = atol(values[2])

    fn __str__(self: Self) -> String:
        return String() + "{" + self.source + "->" + (self.source + self.range - 1) + "}" + "=>{" + 
                self.destination + "->" + (self.destination + self.range - 1) + "}"

@value
struct Map(Stringable, CollectionElement):
    var name: String
    var ranges: DynamicVector[Range]

    var source_entity: String
    var destination_entity: String

    fn __str__(self: Self) -> String:
        var buffer = String(self.name) + "\n"
        for i in range(len(self.ranges)):
            buffer += str(self.ranges[i]) + "\n"

        return buffer

    def map(self: Self, ids: Set) -> Set:
        # Go through each map interval, pluck the src range that overlaps with ids out and append the dest range to the result
        # (1, 9) * { (1,2)->(4,5), (3)->(1), (4,5)->(2,3) } => (4,5), (1,1), (2,3), (6, 9) 

        var mapped_ids = Set(DynamicVector[Interval]())

        # Iterate over the maps to apply
        for i in range(len(self.ranges)):
            let src_interval =  Interval(self.ranges[i].source, self.ranges[i].source + self.ranges[i].range - 1)
            let dest_interval = Interval(self.ranges[i].destination, self.ranges[i].destination + self.ranges[i].range - 1)

            for j in range(len(ids.elements)):

                if src_interval.overlaps(ids.elements[j]):
                    # Find the overlap
                    let lower = max(src_interval.left, ids.elements[j].left)
                    let upper = min(src_interval.right, ids.elements[j].right)
                    let a_m = Interval(lower, upper)

                    # Pop a_m from a
                    ids.remove(a_m)

                    # Add map(a_m) to result
                    # map(a_m):
                    #   find a_m in src_interval (offset + range)
                    #   find map(a_m) from (dest_interval.left + offset, dest_interval.left + offset + range)
                    let offset = lower - src_interval.left
                    let range = upper - lower
                    let mapped_am = Interval(dest_interval.left + offset, dest_interval.left + offset + range)
                    mapped_ids.elements.append(mapped_am)

                    # print("a_m = ", a_m)
                    # print("map(a_m) = ", mapped_am)

        # Add pass through
        for i in range(len(ids.elements)):
            if ids.elements[i] != Interval.empty:
                mapped_ids.elements.append(ids.elements[i])

        mapped_ids.drop_empty()

        return mapped_ids


    def map(self: Self, id: Int) -> Entity:
        var next_id = id
        for i in range(len(self.ranges)):
            if self.ranges[i].contains(id):
                let offset = id - self.ranges[i].source
                next_id = self.ranges[i].destination + offset

                return Entity(self.destination_entity, next_id)
        
        return Entity(self.destination_entity, next_id)

    def __parse_range_block(self: Self, range_block: DynamicVector[String]) -> DynamicVector[Range]:
        var result = DynamicVector[Range]()

        for i in range(len(range_block)):
            result.append(Range(range_block[i]))
        
        return result


    fn __init__(inout self: Self, name: String, fname: String) raises:
        self.name = name
        self.ranges = DynamicVector[Range]()
        self.source_entity = ""
        self.destination_entity = ""

        var data = String("")

        with open(fname, 'r') as f:
            data = f.read()

        let lines = data.split("\n")
        var start=False

        var buffer = DynamicVector[String]()
        for i in range(len(lines)):

            if start:
                if ~(lines[i] == ""):
                    buffer.append(lines[i])
                else:
                    break

            if lines[i]==(name + " map:"):
                self.source_entity = lines[i].split(" ")[0].split("-")[0]
                self.destination_entity = lines[i].split(" ")[0].split("-")[2]
                start=True

        self.ranges = self.__parse_range_block(buffer)


def promote(entity: EntityRange, maps: DynamicVector[Map]) -> EntityRange:
    var cur_entity = entity
    for i in range(len(maps)):
        # Go through the list of source ranges and apply this map
        let next_ids = maps[i].map(cur_entity.ids)
        cur_entity = EntityRange(maps[i].destination_entity, next_ids)

    return cur_entity

def promote(entity: Entity, maps: DynamicVector[Map]) -> Entity:
    var cur_entity = entity
    for i in range(len(maps)):
        let next_pair = maps[i].map(cur_entity.id)
        # print(cur_entity, "=>", maps[i].map(cur_entity.id))
        cur_entity = maps[i].map(cur_entity.id)
        
    return cur_entity

def part1(fname: String):
    var seeds = DynamicVector[Int]()

    with open(fname, 'r') as f:
        let nums = f.read().split("\n")[0].split(":")[1].split(" ")
        for i in range(len(nums)):
            try:
                seeds.append(atol(nums[i]))
            except e:
                pass

    var maps = DynamicVector[Map]()
    maps.append(Map("seed-to-soil", fname))
    maps.append(Map("soil-to-fertilizer", fname))
    maps.append(Map("fertilizer-to-water", fname))
    maps.append(Map("water-to-light", fname))
    maps.append(Map("light-to-temperature", fname))
    maps.append(Map("temperature-to-humidity", fname))
    maps.append(Map("humidity-to-location", fname))

    var lowest = -1
    for i in range(len(seeds)):
        let tmp = promote(Entity("seed", seeds[i]), maps).id

        if lowest > tmp or lowest < 0:
            lowest = tmp
            
    return lowest

def part2(fname: String) -> Int:
    var seeds = EntityRange("seed", Set(DynamicVector[Interval]()))

    with open(fname, 'r') as f:
        let nums = f.read().split("\n")[0].split(":")[1].split(" ")

        for i in range(1, len(nums)-1, 2):
            try:
                seeds.ids.elements.append(Interval(atol(nums[i]), atol(nums[i]) + atol(nums[i+1]) - 1))
            except e:
                pass

    var maps = DynamicVector[Map]()
    maps.append(Map("seed-to-soil", fname))
    maps.append(Map("soil-to-fertilizer", fname))
    maps.append(Map("fertilizer-to-water", fname))
    maps.append(Map("water-to-light", fname))
    maps.append(Map("light-to-temperature", fname))
    maps.append(Map("temperature-to-humidity", fname))
    maps.append(Map("humidity-to-location", fname))

    let locations: EntityRange = promote(EntityRange("seed", seeds.ids), maps)

    # Find lowest location (the entity range result is not necessarily sorted)
    var lowest = locations.ids.elements[0].left
    for i in range(len(locations.ids.elements)):
        lowest = min(lowest, locations.ids.elements[i].left)

    return lowest


def main():
    print(part2("day5.input"))