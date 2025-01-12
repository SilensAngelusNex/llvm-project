// RUN: mlir-opt %s -test-linalg-greedy-fusion -split-input-file | FileCheck %s

#map = affine_map<(d0, d1)[s0, s1, s2] -> (d0 * s1 + s0 + d1 * s2)>
#id_2d = affine_map<(d0, d1) -> (d0, d1)>
#pointwise_2d_trait = {
  indexing_maps = [#id_2d, #id_2d, #id_2d],
  iterator_types = ["parallel", "parallel"]
}
func @fuse_indexed_generic_consumer(%A: memref<?x?xf32>,
                                    %B: memref<?x?xf32>,
                                    %C: memref<?x?xf32>,
                                    %D: memref<?x?xf32>) {
  linalg.generic #pointwise_2d_trait
    ins(%A, %B: memref<?x?xf32>, memref<?x?xf32>)
   outs(%C : memref<?x?xf32>) {
  ^bb0(%e: f32, %arg5: f32, %arg6: f32):   // no predecessors
    %2 = addf %e, %arg5 : f32
    linalg.yield %2 : f32
  }
  %c1 = constant 1 : index
  %c0 = constant 0 : index
  %c25 = constant 25 : index
  %c10 = constant 10 : index
  %0 = memref.dim %C, %c0 : memref<?x?xf32>
  %1 = memref.dim %C, %c1 : memref<?x?xf32>
  %2 = memref.dim %D, %c0 : memref<?x?xf32>
  %3 = memref.dim %D, %c1 : memref<?x?xf32>
  scf.for %arg2 = %c0 to %0 step %c10 {
    scf.for %arg3 = %c0 to %1 step %c25 {
      %4 = memref.subview %C[%arg2, %arg3][%c10, %c25][%c1, %c1] :
          memref<?x?xf32> to memref<?x?xf32, #map>
      %5 = memref.subview %D[%arg2, %arg3][%c10, %c25][%c1, %c1] :
          memref<?x?xf32> to memref<?x?xf32, #map>
      linalg.indexed_generic {
        indexing_maps = [#id_2d, #id_2d],
        iterator_types = ["parallel", "parallel"]}
        ins(%4 : memref<?x?xf32, #map>)
       outs(%5 : memref<?x?xf32, #map>) {
      ^bb0(%arg4: index, %arg5: index, %arg6: f32, %arg7: f32):
        %6 = addi %arg4, %arg2 : index
        %7 = addi %arg5, %arg3 : index
        %8 = index_cast %6 : index to i32
        %9 = sitofp %8 : i32 to f32
        %10 = index_cast %7 : index to i32
        %11 = sitofp %10 : i32 to f32
        %12 = addf %9, %11 : f32
        linalg.yield %12 : f32
      }
    }
  }
  return
}
// CHECK-LABEL: func @fuse_indexed_generic_consumer
// CHECK:  scf.for
// CHECK:    scf.for
// CHECK-NOT:  scf.for
// CHECK:      linalg.generic
// CHECK-NOT:    addi
// CHECK:        addf
// CHECK:      linalg.generic
// CHECK:        index_cast

// -----

#map = affine_map<(d0, d1)[s0, s1, s2] -> (d0 * s1 + s0 + d1 * s2)>
#id_2d = affine_map<(d0, d1) -> (d0, d1)>
#pointwise_2d_trait = {
  indexing_maps = [#id_2d, #id_2d, #id_2d],
  iterator_types = ["parallel", "parallel"]
}
func @fuse_indexed_consumer(%A: memref<?x?xf32>,
                                    %B: memref<?x?xf32>,
                                    %C: memref<?x?xf32>,
                                    %D: memref<?x?xf32>) {
  linalg.generic #pointwise_2d_trait
    ins(%A, %B: memref<?x?xf32>, memref<?x?xf32>)
   outs(%C : memref<?x?xf32>) {
  ^bb0(%e: f32, %arg5: f32, %arg6: f32):   // no predecessors
    %2 = addf %e, %arg5 : f32
    linalg.yield %2 : f32
  }
  %c1 = constant 1 : index
  %c0 = constant 0 : index
  %c25 = constant 25 : index
  %c10 = constant 10 : index
  %0 = memref.dim %C, %c0 : memref<?x?xf32>
  %1 = memref.dim %C, %c1 : memref<?x?xf32>
  %2 = memref.dim %D, %c0 : memref<?x?xf32>
  %3 = memref.dim %D, %c1 : memref<?x?xf32>
  scf.for %arg2 = %c0 to %0 step %c10 {
    scf.for %arg3 = %c0 to %1 step %c25 {
      %4 = memref.subview %C[%arg2, %arg3][%c10, %c25][%c1, %c1] :
          memref<?x?xf32> to memref<?x?xf32, #map>
      %5 = memref.subview %D[%arg2, %arg3][%c10, %c25][%c1, %c1] :
          memref<?x?xf32> to memref<?x?xf32, #map>
      linalg.generic {
        indexing_maps = [#id_2d, #id_2d],
        iterator_types = ["parallel", "parallel"]}
        ins(%4 : memref<?x?xf32, #map>)
       outs(%5 : memref<?x?xf32, #map>) {
      ^bb0(%arg4: f32, %arg5: f32):
        %idx0 = linalg.index 0 : index
        %idx1 = linalg.index 1 : index
        %6 = addi %idx0, %arg2 : index
        %7 = addi %idx1, %arg3 : index
        %8 = index_cast %6 : index to i32
        %9 = sitofp %8 : i32 to f32
        %10 = index_cast %7 : index to i32
        %11 = sitofp %10 : i32 to f32
        %12 = addf %9, %11 : f32
        linalg.yield %12 : f32
      }
    }
  }
  return
}
// CHECK-LABEL: func @fuse_indexed_consumer
// CHECK:  scf.for
// CHECK:    scf.for
// CHECK-NOT:  scf.for
// CHECK:      linalg.generic
// CHECK-NOT:    affine.apply
// CHECK:        addf
// CHECK:      linalg.generic
// CHECK:        index_cast

// -----

#map = affine_map<(d0, d1)[s0, s1, s2] -> (d0 * s1 + s0 + d1 * s2)>
#id_2d = affine_map<(d0, d1) -> (d0, d1)>
#pointwise_2d_trait = {
  indexing_maps = [#id_2d, #id_2d, #id_2d],
  iterator_types = ["parallel", "parallel"]
}
func @fuse_indexed_generic_producer(%A: memref<?x?xf32>,
                                    %B: memref<?x?xf32>,
                                    %C: memref<?x?xf32>,
                                    %D: memref<?x?xf32>) {
  %c1 = constant 1 : index
  %c0 = constant 0 : index
  %c25 = constant 25 : index
  %c10 = constant 10 : index
  linalg.indexed_generic #pointwise_2d_trait
      ins(%A, %B : memref<?x?xf32>, memref<?x?xf32>)
     outs(%C : memref<?x?xf32>) {
    ^bb0(%i: index, %j: index, %a: f32, %b: f32, %c: f32): // no predecessors
      %i_int = index_cast %i: index to i32
      %i_float = sitofp %i_int : i32 to f32
      %j_int = index_cast %j: index to i32
      %j_float = sitofp %j_int : i32 to f32
      %ab = addf %a, %b : f32
      %tmp = addf %ab, %i_float : f32
      %out = addf %tmp, %j_float : f32
      linalg.yield %out : f32
  }
  %C_X = memref.dim %C, %c0 : memref<?x?xf32>
  %C_Y = memref.dim %C, %c1 : memref<?x?xf32>
  %D_X = memref.dim %D, %c0 : memref<?x?xf32>
  %D_Y = memref.dim %D, %c1 : memref<?x?xf32>
  scf.parallel (%arg2, %arg3) = (%c0, %c0) to (%C_X, %C_Y) step (%c10, %c25) {
    %C_view = memref.subview %C[%arg2, %arg3][%c10, %c25][%c1, %c1] :
        memref<?x?xf32> to memref<?x?xf32, #map>
    %D_view = memref.subview %D[%arg2, %arg3][%c10, %c25][%c1, %c1] :
        memref<?x?xf32> to memref<?x?xf32, #map>
    linalg.generic {
      indexing_maps = [#id_2d, #id_2d],
      iterator_types = ["parallel", "parallel"]}
      ins(%C_view : memref<?x?xf32, #map>)
     outs(%D_view : memref<?x?xf32, #map>) {
    ^bb0( %a: f32, %b: f32):
      %ab = addf %a, %b : f32
      linalg.yield %ab : f32
    }
  }
  return
}
// CHECK-LABEL: func @fuse_indexed_generic_producer
// CHECK:  scf.parallel ([[I:%.*]], [[J:%.*]]) =
// CHECK-NOT:  scf.parallel
// CHECK:      linalg.generic
// CHECK:          [[i:%.*]] = linalg.index 0 : index
// CHECK:          [[j:%.*]] = linalg.index 1 : index
// CHECK:          [[i_new:%.*]] = addi [[i]], [[I]] : index
// CHECK:          [[j_new:%.*]] = addi [[j]], [[J]] : index
// CHECK:          {{.*}} = index_cast [[i_new]] : index to i32
// CHECK:          {{.*}} = index_cast [[j_new]] : index to i32
// CHECK:      linalg.generic
// CHECK:          addf

// -----

#map = affine_map<(d0, d1)[s0, s1, s2] -> (d0 * s1 + s0 + d1 * s2)>
func @fuse_indexed_producer(%A: memref<?x?xindex>,
                            %B: memref<?x?xindex>) {
  %c1 = constant 1 : index
  %c0 = constant 0 : index
  %c25 = constant 25 : index
  %c10 = constant 10 : index
  linalg.generic {
    indexing_maps = [affine_map<(i, j) -> (j, i)>],
    iterator_types = ["parallel", "parallel"]}
    outs(%A : memref<?x?xindex>) {
  ^bb0(%a: index):   // no predecessors
    %idx0 = linalg.index 0 : index
    %idx1 = linalg.index 1 : index
    %0 = addi %idx0, %idx1 : index
    linalg.yield %0 : index
  }
  %A_X = memref.dim %A, %c0 : memref<?x?xindex>
  %A_Y = memref.dim %A, %c1 : memref<?x?xindex>
  scf.parallel (%arg2, %arg3) = (%c0, %c0) to (%A_X, %A_Y) step (%c10, %c25) {
    %A_view = memref.subview %A[%arg2, %arg3][%c10, %c25][%c1, %c1] :
        memref<?x?xindex> to memref<?x?xindex, #map>
    %B_view = memref.subview %B[%arg2, %arg3][%c10, %c25][%c1, %c1] :
        memref<?x?xindex> to memref<?x?xindex, #map>
    linalg.generic {
      indexing_maps = [affine_map<(i, j) -> (i, j)>,
                       affine_map<(i, j) -> (i, j)>],
      iterator_types = ["parallel", "parallel"]}
      ins(%A_view : memref<?x?xindex, #map>)
      outs(%B_view : memref<?x?xindex, #map>) {
    ^bb0(%a: index, %b: index):
      linalg.yield %a : index
    }
  }
  return
}
// CHECK: [[$MAP:#[a-zA-Z0-9_]*]] = affine_map<(d0, d1) -> (d0 + d1)>
// CHECK-LABEL: func @fuse_indexed_producer
// CHECK:  scf.parallel ([[I:%.*]], [[J:%.*]]) =
// CHECK:    linalg.generic
// CHECK:      [[idx0:%.*]] = linalg.index 0 : index
// CHECK:      [[i_new:%.*]] = affine.apply [[$MAP]]([[idx0]], [[J]])
// CHECK:      [[idx1:%.*]] = linalg.index 1 : index
// CHECK:      [[j_new:%.*]] = affine.apply [[$MAP]]([[idx1]], [[I]])
// CHECK:      [[sum:%.*]] = addi [[i_new]], [[j_new]] : index
// CHECK:      linalg.yield [[sum]] : index
// CHECK:    linalg.generic

// -----

#map = affine_map<(d0, d1)[s0, s1, s2] -> (d0 * s1 + s0 + d1 * s2)>
#id_2d = affine_map<(d0, d1) -> (d0, d1)>
#pointwise_2d_trait = {
  indexing_maps = [#id_2d, #id_2d, #id_2d],
  iterator_types = ["parallel", "parallel"]
}
func @fuse_indexed_generic_producer_tile_second_dim_only(%A: memref<?x?xf32>,
                                                         %B: memref<?x?xf32>,
                                                         %C: memref<?x?xf32>,
                                                         %D: memref<?x?xf32>) {
  %c1 = constant 1 : index
  %c3 = constant 3 : index
  %c0 = constant 0 : index
  linalg.indexed_generic #pointwise_2d_trait
    ins(%A, %B: memref<?x?xf32>, memref<?x?xf32>)
   outs(%C : memref<?x?xf32>) {
    ^bb0(%i: index, %j: index, %a: f32, %b: f32, %c: f32): // no predecessors
      %i_int = index_cast %i: index to i32
      %i_float = sitofp %i_int : i32 to f32
      %j_int = index_cast %j: index to i32
      %j_float = sitofp %j_int : i32 to f32
      %ab = addf %a, %b : f32
      %tmp = addf %ab, %i_float : f32
      %out = addf %tmp, %j_float : f32
      linalg.yield %out : f32
  }
  %C_X = memref.dim %C, %c0 : memref<?x?xf32>
  %C_Y = memref.dim %C, %c1 : memref<?x?xf32>
  %D_X = memref.dim %D, %c0 : memref<?x?xf32>
  %D_Y = memref.dim %D, %c1 : memref<?x?xf32>
  %3 = linalg.range %c0 : %C_Y : %c3 : !linalg.range
  scf.parallel (%j) = (%c0) to (%C_Y) step (%c3) {
    %0 = affine.min affine_map<(d0, d1, d2) -> (d0, d1 - d2)>(%c3, %C_Y, %j)
    %C_view = memref.subview %C[%c0, %j] [%C_X, %0] [%c1, %c1] :
      memref<?x?xf32> to memref<?x?xf32, #map>

    %1 = affine.min affine_map<(d0, d1, d2) -> (d0, d1 - d2)>(%c3, %D_Y, %j)
    %D_view = memref.subview %D[%c0, %j] [%D_X, %1] [%c1, %c1] :
      memref<?x?xf32> to memref<?x?xf32, #map>

    linalg.generic {
      indexing_maps = [#id_2d, #id_2d],
      iterator_types = ["parallel", "parallel"]}
      ins(%C_view : memref<?x?xf32, #map>)
     outs(%D_view : memref<?x?xf32, #map>) {
    ^bb0( %a: f32, %b: f32):
      %ab = addf %a, %b : f32
      linalg.yield %ab : f32
    }
    scf.yield
  }
  return
}
// CHECK-LABEL: func @fuse_indexed_generic_producer_tile_second_dim_only
// CHECK:  [[C0:%.*]] = constant 0 : index
// CHECK:  scf.parallel ([[J:%.*]]) =
// CHECK-NOT:  scf.parallel
// CHECK:      linalg.generic
// CHECK:          [[i:%.*]] = linalg.index 0 : index
// CHECK:          [[j:%.*]] = linalg.index 1 : index
// CHECK:          [[j_new:%.*]] = addi [[j]], [[J]] : index
// CHECK:          {{.*}} = index_cast [[i]] : index to i32
// CHECK:          {{.*}} = index_cast [[j_new]] : index to i32
// CHECK:      linalg.generic
// CHECK:          addf

// -----

#map = affine_map<(d0, d1)[s0, s1, s2] -> (d0 * s1 + s0 + d1 * s2)>
func @fuse_indexed_producer_tiled_second_dim_only(%A: memref<?x?xindex>,
                                                  %B: memref<?x?xindex>) {
  %c1 = constant 1 : index
  %c0 = constant 0 : index
  %c25 = constant 25 : index
  linalg.generic {
    indexing_maps = [affine_map<(i, j) -> (i, j)>],
    iterator_types = ["parallel", "parallel"]}
    outs(%A : memref<?x?xindex>) {
  ^bb0(%a: index):   // no predecessors
    %idx0 = linalg.index 0 : index
    %idx1 = linalg.index 1 : index
    %0 = addi %idx0, %idx1 : index
    linalg.yield %0 : index
  }
  %A_X = memref.dim %A, %c0 : memref<?x?xindex>
  %A_Y = memref.dim %A, %c1 : memref<?x?xindex>
  scf.parallel (%arg3) = (%c0) to (%A_Y) step (%c25) {
    %A_view = memref.subview %A[%c0, %arg3][%A_X, %c25][%c1, %c1] :
        memref<?x?xindex> to memref<?x?xindex, #map>
    %B_view = memref.subview %B[%c0, %arg3][%A_X, %c25][%c1, %c1] :
        memref<?x?xindex> to memref<?x?xindex, #map>
    linalg.generic {
      indexing_maps = [affine_map<(i, j) -> (i, j)>,
                       affine_map<(i, j) -> (i, j)>],
      iterator_types = ["parallel", "parallel"]}
      ins(%A_view : memref<?x?xindex, #map>)
      outs(%B_view : memref<?x?xindex, #map>) {
    ^bb0(%a: index, %b: index):
      linalg.yield %a : index
    }
  }
  return
}
// CHECK: [[$MAP:#[a-zA-Z0-9_]*]] = affine_map<(d0, d1) -> (d0 + d1)>
// CHECK-LABEL: func @fuse_indexed_producer_tiled_second_dim_only
// CHECK:  scf.parallel ([[J:%.*]]) =
// CHECK:    linalg.generic
// CHECK:      [[idx0:%.*]] = linalg.index 0 : index
// CHECK:      [[idx1:%.*]] = linalg.index 1 : index
// CHECK:      [[j_new:%.*]] = affine.apply [[$MAP]]([[idx1]], [[J]])
// CHECK:      [[sum:%.*]] = addi [[idx0]], [[j_new]] : index
// CHECK:      linalg.yield [[sum]] : index
// CHECK:    linalg.generic

