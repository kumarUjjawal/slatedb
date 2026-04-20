use std::ops::Range;

use bytes::Bytes;

use crate::error::SlateDBError;

pub(crate) trait ReadOnlyBlob {
    async fn len(&self) -> Result<u64, SlateDBError>;

    async fn read_range(&self, range: Range<u64>) -> Result<Bytes, SlateDBError>;

    async fn read_suffix(&self, suffix: u64) -> Result<(Bytes, u64), SlateDBError> {
        let len = self.len().await?;
        let start = len.saturating_sub(suffix);
        let bytes = self.read_range(start..len).await?;
        Ok((bytes, len))
    }

    #[allow(dead_code)]
    async fn read(&self) -> Result<Bytes, SlateDBError>;
}
