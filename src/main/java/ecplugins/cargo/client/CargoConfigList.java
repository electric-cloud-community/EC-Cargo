
// ESXConfigList.java --
//
// ESXConfigList.java is part of ElectricCommander.
//
// Copyright (c) 2005-2010 Electric Cloud, Inc.
// All rights reserved.
//

package ecplugins.cargo.client;

import java.util.List;
import java.util.Map;
import java.util.Set;
import java.util.TreeMap;

import com.google.gwt.user.client.ui.ListBox;
import com.google.gwt.xml.client.Document;
import com.google.gwt.xml.client.Node;
import com.google.gwt.xml.client.XMLParser;

import static com.electriccloud.commander.gwt.client.util.XmlUtil.getNodeByName;
import static com.electriccloud.commander.gwt.client.util.XmlUtil.getNodeValueByName;
import static com.electriccloud.commander.gwt.client.util.XmlUtil.getNodesByName;

public class CargoConfigList
{

    //~ Instance fields --------------------------------------------------------

    private final Map<String, CargoConfigInfo> m_configInfo =
        new TreeMap<String, CargoConfigInfo>();

    //~ Methods ----------------------------------------------------------------

    public void addConfig(
            String configName,
            String configContainer)
    {
        m_configInfo.put(configName, new CargoConfigInfo(configContainer));
    }

    public String parseResponse(String cgiResponse)
    {
        Document document     = XMLParser.parse(cgiResponse);
        Node     responseNode = getNodeByName(document, "response");
        String   error        = getNodeValueByName(responseNode, "error");

        if (error != null && !error.isEmpty()) {
            return error;
        }

        Node       configListNode = getNodeByName(responseNode, "cfgs");
        List<Node> configNodes    = getNodesByName(configListNode, "cfg");

        for (Node configNode : configNodes) {
            String configName   = getNodeValueByName(configNode, "name");
            String configContainer = getNodeValueByName(configNode, "container");

            addConfig(configName, configContainer);
        }

        return null;
    }

    public void populateConfigListBox(ListBox lb)
    {

        for (String configName : m_configInfo.keySet()) {
            lb.addItem(configName);
        }
    }

    public Set<String> getConfigNames()
    {
        return m_configInfo.keySet();
    }

    public String getConfigContainer(String configName)
    {
        return m_configInfo.get(configName).m_container;
    }

    public String getEditorDefinition(String configName)
    {
        return "EC-Cargo";
    }

    public boolean isEmpty()
    {
        return m_configInfo.isEmpty();
    }

    public void setEditorDefinition(
            String configContainer,
            String editorDefiniton)
    {
    }

    //~ Inner Classes ----------------------------------------------------------

    private class CargoConfigInfo
    {

        //~ Instance fields ----------------------------------------------------

        private String m_container;

        //~ Constructors -------------------------------------------------------

        public CargoConfigInfo(String container)
        {
            m_container = container;
        }
    }
}
