import Swap from '../components/swap'
import {PoolContextProvider} from "../context/PoolContext";

const SwapPage= () => {
  return (
    <PoolContextProvider>
    <Swap />
    </PoolContextProvider>
  )
};

export default SwapPage;
