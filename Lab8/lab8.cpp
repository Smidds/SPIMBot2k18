/* 
 * CS 233 Spring 2018 Lab 8
 * Compile with: clang++ lab8.cpp -o lab8
 */

#include <iostream>
using namespace std;

// Lab 8 part 1
struct Canvas {
    // Height and width of the canvas.
    unsigned int height;
    unsigned int width;
    // The pattern to draw on the canvas.
    unsigned char pattern;
    // Each char* is null-terminated and has same length.
    char** canvas;
};


// Draw a line on canvas from start_pos to end_pos.
// start_pos will always be smaller than end_pos.
void draw_line(unsigned int start_pos, unsigned int end_pos, Canvas* canvas) {
    unsigned int width = canvas->width;
    unsigned int step_size = 1;
    // Check if the line is vertical.
    if (end_pos - start_pos >= width) {
        step_size = width;
    }
    // Update the canvas with the new line.
    for (int pos = start_pos; pos != end_pos + step_size; pos += step_size) {
        canvas->canvas[pos / width][pos % width] = canvas->pattern;
    }
}


// Lab 8 part 2
struct Lines {
    unsigned int num_lines;
    // An int* array of size 2, where first element is an array of start pos
    // and second element is an array of end pos for each line.
    // start pos always has a smaller value than end pos.
    unsigned int* coords[2];
};

struct Solution {
    unsigned int length;
    int* counts;
};


// Mark an empty region as visited on the canvas using flood fill algorithm.
void flood_fill(int row, int col, unsigned char marker, Canvas* canvas) {
    // Check the current position is valid.
    if (row < 0 || col < 0 || row >= canvas->height || col >= canvas->width) {
        return;
    }
    unsigned char curr = canvas->canvas[row][col];
    if (curr != canvas->pattern && curr != marker) {
        // Mark the current pos as visited.
        canvas->canvas[row][col] = marker;
        // Flood fill four neighbors.
        flood_fill(row - 1, col, marker, canvas);
        flood_fill(row, col + 1, marker, canvas);
        flood_fill(row + 1, col, marker, canvas);
        flood_fill(row, col - 1, marker, canvas);
    }
}


// Count the number of disjoint empty area in a given canvas.
unsigned int count_disjoint_regions_step(unsigned char marker,
                                         Canvas* canvas) {
    unsigned int region_count = 0;
    for (unsigned int row = 0; row < canvas->height; row++) {
        for (unsigned int col = 0; col < canvas->width; col++) {
            unsigned char curr_char = canvas->canvas[row][col];
            if (curr_char != canvas->pattern && curr_char != marker) {
                region_count ++;
                flood_fill(row, col, marker, canvas);
            }
        }
    }
    return region_count;
}


// Count the number of disjoint empty area after adding each line.
// Store the count values into the Solution struct. 
void count_disjoint_regions(const Lines* lines, Canvas* canvas,
                            Solution* solution) {
    // Iterate through each step.
    for (unsigned int i = 0; i < lines->num_lines; i++) {
        unsigned int start_pos = lines->coords[0][i];
        unsigned int end_pos = lines->coords[1][i];
        // Draw line on canvas.
        draw_line(start_pos, end_pos, canvas);
        // Run flood fill algorithm on the updated canvas.
        // In each even iteration, fill with marker 'A', otherwise use 'B'.
        unsigned int count = count_disjoint_regions_step('A' + (i % 2), canvas);
        // Update the solution struct. Memory for counts is preallocated.
        solution->counts[i] = count;
    }
}

// Tests.
// Helper functions.
void print_canvas(const Canvas* canvas) {
    cout << "Canvas struct:" << endl;
    cout << "  height = " << canvas->height << endl;
    cout << "  width = " << canvas->width << endl;
    cout << "  pattern = " << canvas->pattern << endl;
    cout << "  canvas = " << endl;
    for (int i = 0; i < canvas->height; i++) {
        cout << "  " << canvas->canvas[i] << endl;
    }
}

void init_square_canvas(unsigned int size, Canvas* canvas) {
    canvas->width = size;
    canvas->height = size;
    canvas->pattern = '#';
    canvas->canvas = new char* [size];
    for (int i = 0; i < canvas->height; i++) {
        canvas->canvas[i] = new char [size + 1];
        for (int j = 0; j < size; j++) {
            canvas->canvas[i][j] = '.';
        }
        canvas->canvas[i][size] = '\0';
    }
}

void test_draw_line() {
    Canvas canvas;
    init_square_canvas(5, &canvas);
    // Draw a horizontal line.
    draw_line(10, 14, &canvas);
    // Draw a vertical line.
    draw_line(2, 22, &canvas);
    print_canvas(&canvas);
}

void test_flood_fill() {
    Canvas canvas;
    init_square_canvas(5, &canvas);
    // Draw lines.
    for (int i = 0; i < 5; i++) {
        canvas.canvas[i][2] = canvas.pattern;
        canvas.canvas[2][i] = canvas.pattern;
    }
    // This call should not modify the canvas as canvas[2][2] is '#'.
    flood_fill(2, 2, 'A', &canvas);
    print_canvas(&canvas);
    // This call should mark the upper left region as 'A's.
    flood_fill(0, 0, 'A', &canvas);
    print_canvas(&canvas);
}

void test_count_disjoint_regions_step() {
    Canvas canvas;
    init_square_canvas(3, &canvas);
    // Draw lines.
    for (int i = 0; i < 3; i++) {
        canvas.canvas[i][1] = canvas.pattern;
        canvas.canvas[1][i] = canvas.pattern;
    }
    // The test square canvas has a vertical line at column 2 and
    // a horizontal line at row 2, so there are 4 disjoint empty spots.
    unsigned int count = count_disjoint_regions_step('A', &canvas);
    print_canvas(&canvas);
    cout << "#disjoint regions = " << count << endl;
}

void test_count_disjoint_regions() {
    // Initialize Lines.
    Lines lines;
    lines.num_lines = 2;
    unsigned int start_pos[2] = {2, 10};
    unsigned int end_pos[2] = {22, 14};
    lines.coords[0] = start_pos;
    lines.coords[1] = end_pos;
    // Initialize Canvas.
    Canvas canvas;
    init_square_canvas(5, &canvas);
    // Initialize Solution.
    Solution solution;
    solution.length = lines.num_lines;
    solution.counts = new int [lines.num_lines];
    count_disjoint_regions(&lines, &canvas, &solution);
    print_canvas(&canvas);
    cout << "Solution struct:" << endl;
    cout << "  length = " << solution.length << endl;
    cout << "  counts = {";
    for (int i = 0; i < solution.length - 1; i++) {
        cout << solution.counts[i] << ", ";
    }
    cout << solution.counts[solution.length - 1] << "}" << endl;
}

int main() {
    // Part1.
    test_draw_line();
    // Part2.
    test_flood_fill();
    test_count_disjoint_regions_step();
    test_count_disjoint_regions();
    return 0;
}
