# Nether Pathfinder

This is a clone of nether-pathfinder.  

**Read-only / No Support**  

*The differences from the original have been kept with git log. However, I am currently interested in AI and the metaverse, so I will not make any further updates or respond to questions.* The changed files from b5af910d164543fb7522f3cf61a5a57a6f373c2b are as follows:

- README.md
- java/build.gradle
- java/build.gradle:Zone.Identifier
- java/gradlew.bat:Zone.Identifier
- java/gradlew:Zone.Identifier
- java/multiplat_build.sh
- java/multiplat_build.sh:Zone.Identifier
- java/settings.gradle:Zone.Identifier
- java/zigar.sh
- java/zigar.sh:Zone.Identifier
- java/zigcc.sh
- java/zigcc.sh.bak
- java/zigcc.sh.bak:Zone.Identifier
- java/zigcc.sh:Zone.Identifier
- java/zigcxx.sh
- java/zigcxx.sh.bak
- java/zigcxx.sh.bak:Zone.Identifier
- java/zigcxx.sh:Zone.Identifier
- java/zigranlib.sh
- java/zigranlib.sh:Zone.Identifier
- java/zigrc.sh
- java/zigrc.sh:Zone.Identifier
- src/PathFinder.cpp
- src/PathFinder.cpp:Zone.Identifier


High performance pathfinder for Minecraft's nether dimension, useful for travelling by elytra.

This repo is the core library for pathfinding thus is not useful on its own. See [Baritone's elytra branch](https://github.com/cabaletta/baritone/tree/elytra) or [nether-pathfinder-mod](https://github.com/babbaj/nether-pathfinder-mod) for integration inside of a forge mod.

# Building
The native shared library can be built like a typical cmake project but requires clang 13 (gcc currently outputs broken code).

The full java library with native code can be built by the gradle project in the `java` subdirectory and uses `zig cc` to build the native code (zig 0.9.1 is known to work).

# Performance
On my Ryzen 5900x in Linux it pathfinds around 25,000 blocks/second.

Multithreading is used to improve performance but no more than 12 threads will be used.

# Optimization tricks

Nether-pathfinder consists of 2 main parts: the pathfinder and the chunk generator. 
The chunk generator is essentially just the 1.12.2 code for nether world gen copy/pasted into C++ but with a couple optimizations. 
Along with unnecessary features being removed and all allocation being optimized out, there is this code:
![image](https://github.com/babbaj/nether-pathfinder/assets/12820770/ab9e5dc4-b569-4ff3-b99a-60e323cc1359)
I can't explain what these do but what is important to note is that they take a long time to compute (dozens of microseconds), and they have no dependencies on each other. 
To optimize this I made a simple [low latency, fixed size, buggy, thread pool](https://github.com/babbaj/nether-pathfinder/blob/master/src/ParallelExecutor.h) that takes in a few closures and returns their results in a tuple.
![image](https://github.com/babbaj/nether-pathfinder/assets/12820770/781095f3-dfe6-469c-af76-2f8cb665a385)
This brought the total time to generate a chunk from over 100us to around 50us.

Optimizing the A* pathfinder was largely accomplished by storing chunk data in a simple [linear octree](https://github.com/babbaj/nether-pathfinder/blob/master/src/Chunk.h) (basically an array of 4 16 wide cubes, each of which is an array of 8 wide cubes, and so on). 
Because this data structure stores the contents of each cube in a linear chunk of memory, it is very easy for the CPU to tell if a cube is made entirely of air. 
A* takes advantage of this and will try to explore the world with largest possible cube sizes, allowing it to make huge leaps (you can think of it as the search graph being greatly simplified).
This data structure later became useful when adding ray casting for similar reasons.

Another significant optimization (found by Leijurv) to A*, was using the previously mentioned thread pool to [compute all neighboring chunks in parallel](https://github.com/babbaj/nether-pathfinder/blob/v1.1/src/PathFinder.cpp#L303)

Because the time it takes A* to complete does not scale linearly with distance, pathfinding long distance is actually accomplished by running A* for no 500ms and splicing together many invocations of A*. 
This incidentally has the benefit of providing a relatively immediate result but is not ideal because it makes the whole algorithm non deterministic.
