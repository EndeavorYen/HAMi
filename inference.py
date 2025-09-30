import torch
import time
import os
import sys

def main():
    # 1. 檢查 GPU 可見性
    if not torch.cuda.is_available():
        print("Error: PyTorch cannot find any CUDA-enabled GPUs.", flush=True)
        return

    device_count = torch.cuda.device_count()
    print(f"PyTorch sees {device_count} device(s).", flush=True)

    if device_count == 0:
        print("No GPU available to PyTorch, exiting.", flush=True)
        return

    # 2. 測試記憶體分配 (反快取版本)
    mem_limit_mb = int(os.getenv('EXPECTED_MEM_LIMIT_MB', '1024'))

    try:
        size1 = int(mem_limit_mb * 0.8)  # 80% 配額
        size2 = int(mem_limit_mb * 0.3)  # 30% 配額 (80% + 30% > 100%)

        print(f"\nAttempting to allocate a {size1} MB tensor (within limit)...", flush=True)
        tensor1 = torch.randn(size1 * 1024 * 1024 // 4, device='cuda')
        print(f"SUCCESS: First allocation of {size1} MB succeeded.", flush=True)

        print(f"\nAttempting to allocate a second {size2} MB tensor (total exceeds limit)...", flush=True)
        # 這次呼叫將觸發新的 cudaMalloc，因為記憶體池不足，且總量會超過限制
        tensor2 = torch.randn(size2 * 1024 * 1024 // 4, device='cuda')

        # 如果程式能執行到這裡，表示限制失敗
        print("FAILURE: Second allocation succeeded unexpectedly.", flush=True)

    except RuntimeError as e:
        if "out of memory" in str(e):
            print("\nSUCCESS: Second allocation failed with 'CUDA out of memory' as expected!", flush=True)
        else:
            print(f"FAILURE: Caught an unexpected runtime error: {e}", flush=True)
    except Exception as e:
        print(f"FAILURE: Caught an unexpected exception: {e}", flush=True)

    # 3. 測試算力限制 (如果記憶體測試成功，可以取消註解來測試)
    # print("\nStarting a long-running matrix multiplication to test compute slicing...", flush=True)
    # print("You can now check 'nvidia-smi' on the HOST machine to observe GPU utilization.", flush=True)
    # a = torch.randn(15000, 15000, device='cuda')
    # b = torch.randn(15000, 15000, device='cuda')
    # start_time = time.time()
    # while True:
    #     c = torch.matmul(a, b)
    #     if time.time() - start_time > 300: # 執行 5 分鐘
    #          break
    # print("Compute test finished.", flush=True)

if __name__ == "__main__":
    main()
