import java.util.ArrayList;
import java.util.List;
import javax.inject.Inject;

import org.daisy.dotify.api.embosser.FileFormat;
import org.daisy.dotify.api.table.Table;
import org.daisy.pipeline.braille.common.Provider;
import static org.daisy.pipeline.braille.common.Provider.util.dispatch;
import org.daisy.pipeline.braille.common.Query;
import org.daisy.pipeline.braille.common.Query.MutableQuery;
import static org.daisy.pipeline.braille.common.Query.util.mutableQuery;
import static org.daisy.pipeline.braille.common.Query.util.query;
import org.daisy.pipeline.braille.pef.FileFormatProvider;
import org.daisy.pipeline.braille.pef.TableProvider;

import org.daisy.pipeline.junit.AbstractTest;

import org.junit.Test;
import static org.junit.Assert.assertEquals;

import org.ops4j.pax.exam.ProbeBuilder;
import org.ops4j.pax.exam.TestProbeBuilder;

public class PefCoreTest extends AbstractTest {
	
	@Inject
	public DispatchingTableProvider tableProvider;
	
	@Test
	public void testBrailleUtilsTableCatalog() {
		MutableQuery q = mutableQuery();
		q.add("id", "org.daisy.braille.impl.table.DefaultTableProvider.TableType.EN_US");
		Table table = tableProvider.get(q).iterator().next();
		assertEquals("FOOBAR", table.newBrailleConverter().toText("⠋⠕⠕⠃⠁⠗"));
	}
	
	@Test
	public void testLocaleBasedTableProviderEn() {
		Table table = tableProvider.get(query("(locale:en)")).iterator().next();
		assertEquals("FOOBAR", table.newBrailleConverter().toText("⠋⠕⠕⠃⠁⠗"));
	}
	
	@Test
	public void testLocaleBasedTableProviderNl() {
		Table table = tableProvider.get(query("(locale:nl)")).iterator().next();
		assertEquals("foobar", table.newBrailleConverter().toText("⠋⠕⠕⠃⠁⠗"));
	}
	
	@Inject
	public DispatchingFileFormatProvider formatProvider;
	
	@Test
	public void testBrailleUtilsFileFormatCatalog() {
		MutableQuery q = mutableQuery();
		q.add("format", "org_daisy.BrailleEditorsFileFormatProvider.FileType.BRF");
		q.add("table", "org_daisy.EmbosserTableProvider.TableType.MIT");
		formatProvider.get(q).iterator().next();
	}
	
	@Test
	public void testBrailleUtilsEmbosserAsFileFormatCatalog() {
		MutableQuery q = mutableQuery();
		q.add("embosser", "com_braillo.BrailloEmbosserProvider.EmbosserType.BRAILLO_200");
		q.add("locale", "nl");
		formatProvider.get(q).iterator().next();
	}
	
	@Override
	protected String[] testDependencies() {
		return new String[] {
			brailleModule("common-utils"),
			pipelineModule("file-utils"),
			"org.daisy.dotify:dotify.library:?",
			"org.daisy.pipeline:calabash-adapter:?",
			// because the exclusion of com.fasterxml.woodstox:woodstox-core from the dotify.library
			// dependencies causes stax2-api to be excluded too
			"org.codehaus.woodstox:stax2-api:jar:?",
		};
	}
	
	@ProbeBuilder
	public TestProbeBuilder probeConfiguration(TestProbeBuilder probe) {
		probe.setHeader("Service-Component", "OSGI-INF/dispatching-table-provider.xml,"
		                                   + "OSGI-INF/dispatching-file-format-provider.xml");
		return probe;
	}
}
