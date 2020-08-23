//------------------------------------------------------------------------------
// MON86 - Target declarations
//------------------------------------------------------------------------------

#pragma once

// Interrupt vectors

#define vect_trace   0x01
#define vect_break   0x03
#define vect_global  0xFF

// Optimizations

#define MON86_186
